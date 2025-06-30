"""
TR069 ACS (Auto Configuration Server) Implementation
This module handles TR069 protocol communication with CPE/ONU devices
"""

import xml.etree.ElementTree as ET
from datetime import datetime
import uuid
import json
import re
from flask import request, Response
from models import db, Device, DeviceParameter, TR069Session, Task
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# TR069 SOAP namespaces
SOAP_ENV = "http://schemas.xmlsoap.org/soap/envelope/"
CWMP_NS = "urn:dslforum-org:cwmp-1-0"

class TR069ACS:
    """TR069 Auto Configuration Server"""
    
    def __init__(self, app=None):
        self.app = app
        self.active_sessions = {}
        
    def init_app(self, app):
        self.app = app
        
    def handle_request(self):
        """Handle incoming TR069 requests"""
        try:
            # Get request data
            content_type = request.headers.get('Content-Type', '')
            content_length = int(request.headers.get('Content-Length', 0))
            
            if content_length == 0:
                # Empty request - send GetRPCMethods
                return self._create_empty_response()
            
            # Parse SOAP request
            soap_data = request.get_data()
            logger.info(f"Received TR069 request: {soap_data.decode('utf-8', errors='ignore')}")
            
            # Parse XML
            try:
                root = ET.fromstring(soap_data)
            except ET.ParseError:
                logger.error("Failed to parse XML request")
                return self._create_soap_fault("Client", "Invalid XML")
            
            # Extract SOAP body
            body = root.find(f'.//{{{SOAP_ENV}}}Body')
            if body is None:
                logger.error("No SOAP body found")
                return self._create_soap_fault("Client", "No SOAP Body")
            
            # Determine request type and handle accordingly
            if self._is_inform_request(body):
                return self._handle_inform(body)
            elif self._is_get_rpc_methods_response(body):
                return self._handle_get_rpc_methods_response(body)
            elif self._is_set_parameter_values_response(body):
                return self._handle_set_parameter_values_response(body)
            elif self._is_get_parameter_values_response(body):
                return self._handle_get_parameter_values_response(body)
            else:
                logger.warning("Unknown request type")
                return self._create_empty_response()
                
        except Exception as e:
            logger.error(f"Error handling TR069 request: {str(e)}")
            return self._create_soap_fault("Server", str(e))
    
    def _is_inform_request(self, body):
        """Check if request is an Inform message"""
        inform = body.find(f'.//{{{CWMP_NS}}}Inform')
        return inform is not None
    
    def _is_get_rpc_methods_response(self, body):
        """Check if request is GetRPCMethodsResponse"""
        response = body.find(f'.//{{{CWMP_NS}}}GetRPCMethodsResponse')
        return response is not None
    
    def _is_set_parameter_values_response(self, body):
        """Check if request is SetParameterValuesResponse"""
        response = body.find(f'.//{{{CWMP_NS}}}SetParameterValuesResponse')
        return response is not None
    
    def _is_get_parameter_values_response(self, body):
        """Check if request is GetParameterValuesResponse"""
        response = body.find(f'.//{{{CWMP_NS}}}GetParameterValuesResponse')
        return response is not None
    
    def _handle_inform(self, body):
        """Handle Inform message and register/update device (namespace-agnostic)."""
        logger.info("Handling Inform request – universal parser v2")

        def find_text(element, tag_suffix):
            """Return first .text of any descendant whose tag ends with tag_suffix"""
            for elem in element.iter():
                if elem.tag.endswith(tag_suffix):
                    return (elem.text or '').strip()
            return ''

        try:
            serial_number = find_text(body, 'SerialNumber')
            manufacturer  = find_text(body, 'Manufacturer') or 'Unknown'
            product_class = find_text(body, 'ProductClass') or 'Unknown'

            if not serial_number:
                # Fallback to Device.DeviceInfo.SerialNumber in ParameterList
                serial_number = find_text(body, 'DeviceInfo.SerialNumber')
            if not serial_number:
                serial_number = f"UNKNOWN_{uuid.uuid4().hex[:8]}"

            # Pull some optional useful params
            software_version = find_text(body, 'SoftwareVersion')
            hardware_version = find_text(body, 'HardwareVersion')
            ip_address       = find_text(body, 'ExternalIPAddress')

            now = datetime.utcnow()
            device = Device.query.filter_by(serial_number=serial_number).first()
            action = 'update'
            if not device:
                device = Device(serial_number=serial_number,
                                manufacturer=manufacturer,
                                model=product_class,
                                device_type='CPE',
                                registered_at=now)
                db.session.add(device)
                action = 'create'

            device.status            = 'online'
            device.last_inform       = now
            device.software_version  = software_version or device.software_version
            device.hardware_version  = hardware_version or device.hardware_version
            device.ip_address        = ip_address or device.ip_address
            db.session.commit()
            logger.info(f"Device {serial_number} {action}d / refreshed successfully")

            # Push websocket event if socketio present
            try:
                sio = self.app.extensions.get('socketio')
                if sio:
                    sio.emit('device_update', device.to_dict(), namespace='/')
            except Exception as ws_err:
                logger.debug(f"WebSocket emit skipped: {ws_err}")

        except Exception as exc:
            logger.error("Failed to process Inform: %s", exc, exc_info=True)

        # Always respond with InformResponse
        soap_resp = f"""<?xml version='1.0' encoding='UTF-8'?>
<soap:Envelope xmlns:soap='{SOAP_ENV}' xmlns:cwmp='{CWMP_NS}'>
 <soap:Header><cwmp:ID soap:mustUnderstand='1'>{uuid.uuid4()}</cwmp:ID></soap:Header>
 <soap:Body><cwmp:InformResponse><MaxEnvelopes>1</MaxEnvelopes></cwmp:InformResponse></soap:Body>
</soap:Envelope>"""
        return Response(soap_resp, mimetype='text/xml')
    
    def _register_device(self, serial_number, manufacturer, product_class, oui, parameters, current_time, events):
        """Register or update device in database"""
        device = Device.query.filter_by(serial_number=serial_number).first()
        
        if not device:
            # Create new device
            device = Device(
                serial_number=serial_number,
                manufacturer=manufacturer,
                model=product_class,
                device_type='CPE' if 'CPE' in product_class.upper() else 'ONU',
                status='online',
                last_inform=current_time,
                registered_at=datetime.utcnow()
            )
            db.session.add(device)
            logger.info(f"New device registered: {serial_number}")
        else:
            # Update existing device
            device.status = 'online'
            device.last_inform = current_time
            if '1 BOOT' in events:
                device.last_boot = current_time
            logger.info(f"Device updated: {serial_number}")
        
        # Update device parameters
        for param_name, param_value in parameters.items():
            param = DeviceParameter.query.filter_by(
                device_id=device.id,
                parameter_name=param_name
            ).first()
            
            if not param:
                param = DeviceParameter(
                    device_id=device.id,
                    parameter_name=param_name,
                    parameter_value=param_value,
                    updated_at=datetime.utcnow()
                )
                db.session.add(param)
            else:
                param.parameter_value = param_value
                param.updated_at = datetime.utcnow()
        
        db.session.commit()
        return device
    
    def _execute_task(self, task):
        """Execute pending task"""
        task.status = 'in_progress'
        task.started_at = datetime.utcnow()
        db.session.commit()
        
        if task.task_type == 'get_parameters':
            params = json.loads(task.parameters) if task.parameters else {}
            parameter_names = params.get('parameter_names', [])
            return self._create_get_parameter_values_request(parameter_names)
        
        elif task.task_type == 'set_parameters':
            params = json.loads(task.parameters) if task.parameters else {}
            parameter_values = params.get('parameter_values', {})
            return self._create_set_parameter_values_request(parameter_values)
        
        elif task.task_type == 'reboot':
            return self._create_reboot_request()
        
        elif task.task_type == 'factory_reset':
            return self._create_factory_reset_request()
        
        else:
            task.status = 'failed'
            task.error_message = f"Unknown task type: {task.task_type}"
            task.completed_at = datetime.utcnow()
            db.session.commit()
            return self._create_empty_response()
    
    def _create_get_parameter_values_request(self, parameter_names):
        """Create GetParameterValues SOAP request"""
        soap_xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="{SOAP_ENV}" xmlns:cwmp="{CWMP_NS}">
    <soap:Header>
        <cwmp:ID soap:mustUnderstand="1">{uuid.uuid4()}</cwmp:ID>
    </soap:Header>
    <soap:Body>
        <cwmp:GetParameterValues>
            <ParameterNames soap:arrayType="xsd:string[{len(parameter_names)}]">
                {"".join([f"<string>{name}</string>" for name in parameter_names])}
            </ParameterNames>
        </cwmp:GetParameterValues>
    </soap:Body>
</soap:Envelope>'''
        
        return Response(soap_xml, mimetype='text/xml')
    
    def _create_set_parameter_values_request(self, parameter_values):
        """Create SetParameterValues SOAP request"""
        param_structs = ""
        for name, value in parameter_values.items():
            param_structs += f'''
            <ParameterValueStruct>
                <Name>{name}</Name>
                <Value xsi:type="xsd:string">{value}</Value>
            </ParameterValueStruct>'''
        
        soap_xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="{SOAP_ENV}" xmlns:cwmp="{CWMP_NS}" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <soap:Header>
        <cwmp:ID soap:mustUnderstand="1">{uuid.uuid4()}</cwmp:ID>
    </soap:Header>
    <soap:Body>
        <cwmp:SetParameterValues>
            <ParameterList soap:arrayType="cwmp:ParameterValueStruct[{len(parameter_values)}]">
                {param_structs}
            </ParameterList>
            <ParameterKey>key_{int(datetime.utcnow().timestamp())}</ParameterKey>
        </cwmp:SetParameterValues>
    </soap:Body>
</soap:Envelope>'''
        
        return Response(soap_xml, mimetype='text/xml')
    
    def _create_reboot_request(self):
        """Create Reboot SOAP request"""
        soap_xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="{SOAP_ENV}" xmlns:cwmp="{CWMP_NS}">
    <soap:Header>
        <cwmp:ID soap:mustUnderstand="1">{uuid.uuid4()}</cwmp:ID>
    </soap:Header>
    <soap:Body>
        <cwmp:Reboot>
            <CommandKey>reboot_{int(datetime.utcnow().timestamp())}</CommandKey>
        </cwmp:Reboot>
    </soap:Body>
</soap:Envelope>'''
        
        return Response(soap_xml, mimetype='text/xml')
    
    def _create_factory_reset_request(self):
        """Create FactoryReset SOAP request"""
        soap_xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="{SOAP_ENV}" xmlns:cwmp="{CWMP_NS}">
    <soap:Header>
        <cwmp:ID soap:mustUnderstand="1">{uuid.uuid4()}</cwmp:ID>
    </soap:Header>
    <soap:Body>
        <cwmp:FactoryReset/>
    </soap:Body>
</soap:Envelope>'''
        
        return Response(soap_xml, mimetype='text/xml')
    
    def _handle_get_rpc_methods_response(self, body):
        """Handle GetRPCMethodsResponse"""
        logger.info("Handling GetRPCMethodsResponse")
        return self._create_empty_response()
    
    def _handle_set_parameter_values_response(self, body):
        """Handle SetParameterValuesResponse"""
        logger.info("Handling SetParameterValuesResponse")
        return self._create_empty_response()
    
    def _handle_get_parameter_values_response(self, body):
        """Handle GetParameterValuesResponse"""
        logger.info("Handling GetParameterValuesResponse")
        return self._create_empty_response()
    
    def _create_empty_response(self):
        """Create empty HTTP response"""
        return Response('', status=204)
    
    def _create_soap_fault(self, fault_code, fault_string):
        """Create SOAP fault response"""
        soap_xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="{SOAP_ENV}">
    <soap:Body>
        <soap:Fault>
            <faultcode>{fault_code}</faultcode>
            <faultstring>{fault_string}</faultstring>
        </soap:Fault>
    </soap:Body>
</soap:Envelope>'''
        
        return Response(soap_xml, mimetype='text/xml', status=500) 