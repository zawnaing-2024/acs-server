"""
Main Flask Application for TR069 Management Portal
"""

import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
from flask_socketio import SocketIO, emit
from datetime import datetime, timedelta
import json

# Local imports
from config import config
from models import db, User, Device, DeviceParameter, Task, Firmware
from tr069_acs import TR069ACS

def create_app(config_name=None):
    """Application factory"""
    if config_name is None:
        config_name = os.environ.get('FLASK_CONFIG') or 'default'
    
    app = Flask(__name__)
    app.config.from_object(config[config_name])
    
    # Initialize extensions
    db.init_app(app)
    CORS(app, origins=app.config['CORS_ORIGINS'])
    jwt = JWTManager(app)
    socketio = SocketIO(app, cors_allowed_origins=app.config['CORS_ORIGINS'])
    
    # Initialize TR069 ACS
    acs = TR069ACS()
    acs.init_app(app)
    
    # Create tables
    with app.app_context():
        db.create_all()
        
        # Create default admin user if not exists
        admin_user = User.query.filter_by(username='admin').first()
        if not admin_user:
            admin_user = User(
                username='admin',
                email='admin@tr069portal.com',
                role='admin'
            )
            admin_user.set_password('admin123')
            db.session.add(admin_user)
            db.session.commit()
            print("Default admin user created: admin/admin123")
    
    # TR069 ACS Routes
    @app.route('/acs', methods=['GET', 'POST'])
    def tr069_acs_handler():
        """Handle TR069 ACS requests"""
        return acs.handle_request()
    
    # Authentication Routes
    @app.route('/api/auth/login', methods=['POST'])
    def login():
        """User login"""
        try:
            data = request.get_json()
            username = data.get('username')
            password = data.get('password')
            
            if not username or not password:
                return jsonify({'error': 'Username and password required'}), 400
            
            user = User.query.filter_by(username=username).first()
            if not user or not user.check_password(password):
                return jsonify({'error': 'Invalid credentials'}), 401
            
            if not user.is_active:
                return jsonify({'error': 'Account disabled'}), 401
            
            # Update last login
            user.last_login = datetime.utcnow()
            db.session.commit()
            
            # Create access token
            access_token = create_access_token(identity=user.id)
            
            return jsonify({
                'access_token': access_token,
                'user': user.to_dict()
            })
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @app.route('/api/auth/register', methods=['POST'])
    @jwt_required()
    def register():
        """Register new user (admin only)"""
        try:
            current_user_id = get_jwt_identity()
            current_user = User.query.get(current_user_id)
            
            if current_user.role != 'admin':
                return jsonify({'error': 'Admin access required'}), 403
            
            data = request.get_json()
            username = data.get('username')
            email = data.get('email')
            password = data.get('password')
            role = data.get('role', 'user')
            
            if not all([username, email, password]):
                return jsonify({'error': 'Username, email, and password required'}), 400
            
            # Check if user exists
            if User.query.filter_by(username=username).first():
                return jsonify({'error': 'Username already exists'}), 400
            
            if User.query.filter_by(email=email).first():
                return jsonify({'error': 'Email already exists'}), 400
            
            # Create new user
            user = User(
                username=username,
                email=email,
                role=role
            )
            user.set_password(password)
            
            db.session.add(user)
            db.session.commit()
            
            return jsonify({'message': 'User created successfully', 'user': user.to_dict()})
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    # Device Management Routes
    @app.route('/api/devices', methods=['GET'])
    @jwt_required()
    def get_devices():
        """Get list of devices"""
        try:
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 20, type=int)
            device_type = request.args.get('type')
            status = request.args.get('status')
            search = request.args.get('search')
            
            query = Device.query
            
            # Filters
            if device_type:
                query = query.filter(Device.device_type == device_type)
            if status:
                query = query.filter(Device.status == status)
            if search:
                query = query.filter(
                    db.or_(
                        Device.serial_number.contains(search),
                        Device.manufacturer.contains(search),
                        Device.model.contains(search),
                        Device.customer_name.contains(search)
                    )
                )
            
            # Pagination
            devices = query.paginate(
                page=page,
                per_page=per_page,
                error_out=False
            )
            
            return jsonify({
                'devices': [device.to_dict() for device in devices.items],
                'pagination': {
                    'page': page,
                    'per_page': per_page,
                    'total': devices.total,
                    'pages': devices.pages,
                    'has_next': devices.has_next,
                    'has_prev': devices.has_prev
                }
            })
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @app.route('/api/devices/<int:device_id>', methods=['GET'])
    @jwt_required()
    def get_device(device_id):
        """Get device details"""
        try:
            device = Device.query.get_or_404(device_id)
            
            # Get device parameters
            parameters = DeviceParameter.query.filter_by(device_id=device_id).all()
            
            device_data = device.to_dict()
            device_data['parameters'] = [param.to_dict() for param in parameters]
            
            return jsonify(device_data)
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @app.route('/api/devices/<int:device_id>/parameters', methods=['GET'])
    @jwt_required()
    def get_device_parameters(device_id):
        """Get device parameters"""
        try:
            device = Device.query.get_or_404(device_id)
            parameters = DeviceParameter.query.filter_by(device_id=device_id).all()
            
            return jsonify({
                'device_id': device_id,
                'parameters': [param.to_dict() for param in parameters]
            })
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @app.route('/api/devices/<int:device_id>/tasks', methods=['POST'])
    @jwt_required()
    def create_device_task(device_id):
        """Create device task"""
        try:
            device = Device.query.get_or_404(device_id)
            data = request.get_json()
            
            task_type = data.get('task_type')
            parameters = data.get('parameters', {})
            priority = data.get('priority', 5)
            
            if not task_type:
                return jsonify({'error': 'Task type required'}), 400
            
            # Create task
            task = Task(
                device_id=device_id,
                task_type=task_type,
                parameters=json.dumps(parameters) if parameters else None,
                priority=priority
            )
            
            db.session.add(task)
            db.session.commit()
            
            # Emit real-time notification
            socketio.emit('task_created', {
                'task': task.to_dict(),
                'device': device.to_dict()
            })
            
            return jsonify({'message': 'Task created successfully', 'task': task.to_dict()})
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @app.route('/api/tasks', methods=['GET'])
    @jwt_required()
    def get_tasks():
        """Get list of tasks"""
        try:
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 20, type=int)
            status = request.args.get('status')
            device_id = request.args.get('device_id', type=int)
            
            query = Task.query.join(Device)
            
            # Filters
            if status:
                query = query.filter(Task.status == status)
            if device_id:
                query = query.filter(Task.device_id == device_id)
            
            # Order by priority and creation time
            query = query.order_by(Task.priority.asc(), Task.created_at.desc())
            
            # Pagination
            tasks = query.paginate(
                page=page,
                per_page=per_page,
                error_out=False
            )
            
            return jsonify({
                'tasks': [task.to_dict() for task in tasks.items],
                'pagination': {
                    'page': page,
                    'per_page': per_page,
                    'total': tasks.total,
                    'pages': tasks.pages,
                    'has_next': tasks.has_next,
                    'has_prev': tasks.has_prev
                }
            })
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @app.route('/api/dashboard/stats', methods=['GET'])
    @jwt_required()
    def get_dashboard_stats():
        """Get dashboard statistics"""
        try:
            total_devices = Device.query.count()
            online_devices = Device.query.filter_by(status='online').count()
            offline_devices = Device.query.filter_by(status='offline').count()
            
            cpe_devices = Device.query.filter_by(device_type='CPE').count()
            onu_devices = Device.query.filter_by(device_type='ONU').count()
            
            pending_tasks = Task.query.filter_by(status='pending').count()
            active_tasks = Task.query.filter_by(status='in_progress').count()
            
            # Recent devices (last 24 hours)
            yesterday = datetime.utcnow() - timedelta(days=1)
            recent_devices = Device.query.filter(Device.registered_at >= yesterday).count()
            
            return jsonify({
                'total_devices': total_devices,
                'online_devices': online_devices,
                'offline_devices': offline_devices,
                'cpe_devices': cpe_devices,
                'onu_devices': onu_devices,
                'pending_tasks': pending_tasks,
                'active_tasks': active_tasks,
                'recent_devices': recent_devices
            })
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    # WebSocket events
    @socketio.on('connect')
    @jwt_required()
    def handle_connect():
        """Handle client connection"""
        current_user_id = get_jwt_identity()
        emit('connected', {'message': 'Connected to TR069 Portal'})
    
    @socketio.on('disconnect')
    def handle_disconnect():
        """Handle client disconnection"""
        print('Client disconnected')
    
    # Error handlers
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({'error': 'Not found'}), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        return jsonify({'error': 'Internal server error'}), 500
    
    # Health check
    @app.route('/health')
    def health_check():
        return jsonify({'status': 'healthy', 'timestamp': datetime.utcnow().isoformat()})
    
    return app, socketio

# Create app instance
app, socketio = create_app()

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('FLASK_ENV') == 'development'
    
    print(f"Starting TR069 Management Portal on port {port}")
    print(f"ACS URL: http://localhost:{port}/acs")
    print(f"Web Portal: http://localhost:3000")
    
    socketio.run(app, host='0.0.0.0', port=port, debug=debug) 