#!/usr/bin/env python3
"""
Database initialization script for TR069 Management Portal
"""

import os
import sys
from datetime import datetime

# Add the backend directory to the Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app
from models import db, User, Device, DeviceParameter, Firmware

def init_database():
    """Initialize the database with tables and default data"""
    app, _ = create_app()
    
    with app.app_context():
        print("Creating database tables...")
        db.create_all()
        
        # Create default admin user
        admin_user = User.query.filter_by(username='admin').first()
        if not admin_user:
            admin_user = User(
                username='admin',
                email='admin@tr069portal.com',
                role='admin',
                is_active=True
            )
            admin_user.set_password('admin123')
            db.session.add(admin_user)
            print("✓ Created default admin user: admin/admin123")
        else:
            print("✓ Admin user already exists")
        
        # Create demo user
        demo_user = User.query.filter_by(username='demo').first()
        if not demo_user:
            demo_user = User(
                username='demo',
                email='demo@tr069portal.com',
                role='user',
                is_active=True
            )
            demo_user.set_password('demo123')
            db.session.add(demo_user)
            print("✓ Created demo user: demo/demo123")
        else:
            print("✓ Demo user already exists")
        
        # Create sample devices (optional)
        sample_devices = [
            {
                'serial_number': 'CPE001234567890',
                'device_type': 'CPE',
                'manufacturer': 'Huawei',
                'model': 'HG8245H',
                'software_version': '1.0.0',
                'hardware_version': '1.0',
                'mac_address': '00:11:22:33:44:55',
                'ip_address': '192.168.1.100',
                'status': 'offline',
                'customer_name': 'John Doe',
                'location': '123 Main St, City, Country'
            },
            {
                'serial_number': 'ONU987654321',
                'device_type': 'ONU',
                'manufacturer': 'ZTE',
                'model': 'F601',
                'software_version': '2.1.0',
                'hardware_version': '2.0',
                'mac_address': '00:AA:BB:CC:DD:EE',
                'ip_address': '192.168.1.101',
                'status': 'offline',
                'customer_name': 'Jane Smith',
                'location': '456 Oak Ave, City, Country'
            }
        ]
        
        for device_data in sample_devices:
            existing_device = Device.query.filter_by(serial_number=device_data['serial_number']).first()
            if not existing_device:
                device = Device(**device_data)
                db.session.add(device)
                print(f"✓ Created sample device: {device_data['serial_number']}")
        
        # Commit all changes
        db.session.commit()
        print("✓ Database initialization completed successfully!")
        
        # Print connection info
        print("\n" + "="*50)
        print("TR069 Management Portal Setup Complete!")
        print("="*50)
        print("Default Login Credentials:")
        print("  Admin: admin / admin123")
        print("  Demo:  demo / demo123")
        print("")
        print("ACS URL for devices: http://your-server:5000/acs")
        print("Web Portal: http://localhost:3000")
        print("="*50)

if __name__ == '__main__':
    init_database() 