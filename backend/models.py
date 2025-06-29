from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
import uuid
import json

db = SQLAlchemy()

class User(db.Model):
    """User model for authentication and authorization"""
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(20), default='user')  # admin, user, viewer
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login = db.Column(db.DateTime)
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def to_dict(self):
        return {
            'id': self.id,
            'username': self.username,
            'email': self.email,
            'role': self.role,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'last_login': self.last_login.isoformat() if self.last_login else None
        }

class Device(db.Model):
    """Device model for CPE and ONU devices"""
    __tablename__ = 'devices'
    
    id = db.Column(db.Integer, primary_key=True)
    serial_number = db.Column(db.String(100), unique=True, nullable=False)
    device_type = db.Column(db.String(20), nullable=False)  # CPE, ONU
    manufacturer = db.Column(db.String(100))
    model = db.Column(db.String(100))
    software_version = db.Column(db.String(50))
    hardware_version = db.Column(db.String(50))
    mac_address = db.Column(db.String(17))
    ip_address = db.Column(db.String(15))
    connection_request_url = db.Column(db.String(255))
    connection_request_username = db.Column(db.String(100))
    connection_request_password = db.Column(db.String(255))
    
    # Device status
    status = db.Column(db.String(20), default='offline')  # online, offline, error
    last_inform = db.Column(db.DateTime)
    last_boot = db.Column(db.DateTime)
    uptime = db.Column(db.Integer, default=0)  # seconds
    
    # Registration info
    registered_at = db.Column(db.DateTime, default=datetime.utcnow)
    acs_url = db.Column(db.String(255))
    
    # Location and customer info
    customer_name = db.Column(db.String(255))
    location = db.Column(db.String(500))
    latitude = db.Column(db.Float)
    longitude = db.Column(db.Float)
    
    # Relationships
    parameters = db.relationship('DeviceParameter', backref='device', lazy='dynamic', cascade='all, delete-orphan')
    sessions = db.relationship('TR069Session', backref='device', lazy='dynamic', cascade='all, delete-orphan')
    
    def to_dict(self):
        return {
            'id': self.id,
            'serial_number': self.serial_number,
            'device_type': self.device_type,
            'manufacturer': self.manufacturer,
            'model': self.model,
            'software_version': self.software_version,
            'hardware_version': self.hardware_version,
            'mac_address': self.mac_address,
            'ip_address': self.ip_address,
            'status': self.status,
            'last_inform': self.last_inform.isoformat() if self.last_inform else None,
            'last_boot': self.last_boot.isoformat() if self.last_boot else None,
            'uptime': self.uptime,
            'registered_at': self.registered_at.isoformat() if self.registered_at else None,
            'customer_name': self.customer_name,
            'location': self.location,
            'latitude': self.latitude,
            'longitude': self.longitude
        }

class DeviceParameter(db.Model):
    """Device parameter model for storing TR069 parameters"""
    __tablename__ = 'device_parameters'
    
    id = db.Column(db.Integer, primary_key=True)
    device_id = db.Column(db.Integer, db.ForeignKey('devices.id'), nullable=False)
    parameter_name = db.Column(db.String(255), nullable=False)
    parameter_value = db.Column(db.Text)
    parameter_type = db.Column(db.String(50))  # string, int, boolean, dateTime, etc.
    writable = db.Column(db.Boolean, default=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    __table_args__ = (db.UniqueConstraint('device_id', 'parameter_name'),)
    
    def to_dict(self):
        return {
            'id': self.id,
            'parameter_name': self.parameter_name,
            'parameter_value': self.parameter_value,
            'parameter_type': self.parameter_type,
            'writable': self.writable,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

class TR069Session(db.Model):
    """TR069 session model for tracking communication sessions"""
    __tablename__ = 'tr069_sessions'
    
    id = db.Column(db.Integer, primary_key=True)
    device_id = db.Column(db.Integer, db.ForeignKey('devices.id'), nullable=False)
    session_id = db.Column(db.String(100), unique=True, nullable=False)
    session_type = db.Column(db.String(50))  # inform, connection_request, download, etc.
    status = db.Column(db.String(20), default='active')  # active, completed, failed
    started_at = db.Column(db.DateTime, default=datetime.utcnow)
    completed_at = db.Column(db.DateTime)
    error_message = db.Column(db.Text)
    
    # Session data
    request_data = db.Column(db.Text)  # JSON string
    response_data = db.Column(db.Text)  # JSON string
    
    def to_dict(self):
        return {
            'id': self.id,
            'session_id': self.session_id,
            'session_type': self.session_type,
            'status': self.status,
            'started_at': self.started_at.isoformat() if self.started_at else None,
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
            'error_message': self.error_message
        }

class Task(db.Model):
    """Task model for managing device operations"""
    __tablename__ = 'tasks'
    
    id = db.Column(db.Integer, primary_key=True)
    device_id = db.Column(db.Integer, db.ForeignKey('devices.id'), nullable=False)
    task_type = db.Column(db.String(50), nullable=False)  # reboot, factory_reset, download, etc.
    status = db.Column(db.String(20), default='pending')  # pending, in_progress, completed, failed
    priority = db.Column(db.Integer, default=5)  # 1 (highest) to 10 (lowest)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    scheduled_at = db.Column(db.DateTime)
    started_at = db.Column(db.DateTime)
    completed_at = db.Column(db.DateTime)
    
    # Task parameters
    parameters = db.Column(db.Text)  # JSON string
    result = db.Column(db.Text)  # JSON string
    error_message = db.Column(db.Text)
    
    # Relationships
    device = db.relationship('Device', backref=db.backref('tasks', lazy='dynamic'))
    
    def to_dict(self):
        return {
            'id': self.id,
            'device_id': self.device_id,
            'task_type': self.task_type,
            'status': self.status,
            'priority': self.priority,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'scheduled_at': self.scheduled_at.isoformat() if self.scheduled_at else None,
            'started_at': self.started_at.isoformat() if self.started_at else None,
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
            'parameters': json.loads(self.parameters) if self.parameters else None,
            'result': json.loads(self.result) if self.result else None,
            'error_message': self.error_message
        }

class Firmware(db.Model):
    """Firmware model for managing device firmware files"""
    __tablename__ = 'firmware'
    
    id = db.Column(db.Integer, primary_key=True)
    filename = db.Column(db.String(255), nullable=False)
    version = db.Column(db.String(50), nullable=False)
    device_type = db.Column(db.String(20), nullable=False)  # CPE, ONU
    manufacturer = db.Column(db.String(100))
    model = db.Column(db.String(100))
    file_size = db.Column(db.Integer)
    file_path = db.Column(db.String(500))
    checksum = db.Column(db.String(64))  # SHA256
    upload_date = db.Column(db.DateTime, default=datetime.utcnow)
    is_active = db.Column(db.Boolean, default=True)
    description = db.Column(db.Text)
    
    def to_dict(self):
        return {
            'id': self.id,
            'filename': self.filename,
            'version': self.version,
            'device_type': self.device_type,
            'manufacturer': self.manufacturer,
            'model': self.model,
            'file_size': self.file_size,
            'checksum': self.checksum,
            'upload_date': self.upload_date.isoformat() if self.upload_date else None,
            'is_active': self.is_active,
            'description': self.description
        } 