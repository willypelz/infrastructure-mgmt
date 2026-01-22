from flask import Flask, jsonify, request
import redis
import os
import time
from datetime import datetime
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
metrics = PrometheusMetrics(app)

# Redis connection
redis_client = redis.Redis(
    host=os.getenv('REDIS_HOST', 'localhost'),
    port=6379,
    password=os.getenv('REDIS_PASSWORD', ''),
    decode_responses=True
)

@app.route('/')
def home():
    return jsonify({
        'message': 'Flask API with Redis',
        'version': '1.0.0',
        'endpoints': {
            'health': '/health',
            'metrics': '/metrics',
            'cache_test': '/api/cache/<key>',
            'items': '/api/items'
        }
    })

@app.route('/health')
def health():
    """Health check endpoint"""
    try:
        # Test Redis connection
        redis_client.ping()

        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.utcnow().isoformat(),
            'uptime': time.process_time(),
            'redis': 'connected'
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'timestamp': datetime.utcnow().isoformat(),
            'error': str(e)
        }), 503

@app.route('/api/cache/<key>', methods=['GET', 'POST'])
def cache_operations(key):
    """Cache get/set operations"""
    if request.method == 'POST':
        data = request.get_json()
        value = data.get('value')
        ttl = data.get('ttl', 3600)  # Default 1 hour

        redis_client.setex(key, ttl, value)
        return jsonify({
            'success': True,
            'message': f'Key "{key}" set successfully',
            'ttl': ttl
        }), 201
    else:
        value = redis_client.get(key)
        if value:
            ttl = redis_client.ttl(key)
            return jsonify({
                'success': True,
                'key': key,
                'value': value,
                'ttl': ttl
            })
        else:
            return jsonify({
                'success': False,
                'message': f'Key "{key}" not found'
            }), 404

@app.route('/api/items', methods=['GET'])
def get_items():
    """Get all items from Redis"""
    try:
        # Store some sample data if empty
        if not redis_client.exists('items:count'):
            sample_items = [
                {'id': 1, 'name': 'Item 1', 'description': 'First item'},
                {'id': 2, 'name': 'Item 2', 'description': 'Second item'},
                {'id': 3, 'name': 'Item 3', 'description': 'Third item'}
            ]

            for item in sample_items:
                redis_client.hset(f"item:{item['id']}", mapping=item)
            redis_client.set('items:count', len(sample_items))

        # Get all items
        count = int(redis_client.get('items:count') or 0)
        items = []
        for i in range(1, count + 1):
            item = redis_client.hgetall(f'item:{i}')
            if item:
                items.append(item)

        return jsonify({
            'success': True,
            'count': len(items),
            'data': items
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/items', methods=['POST'])
def create_item():
    """Create new item"""
    try:
        data = request.get_json()

        # Get next ID
        count = int(redis_client.get('items:count') or 0)
        new_id = count + 1

        # Create item
        item = {
            'id': new_id,
            'name': data.get('name'),
            'description': data.get('description', '')
        }

        redis_client.hset(f'item:{new_id}', mapping=item)
        redis_client.set('items:count', new_id)

        return jsonify({
            'success': True,
            'data': item
        }), 201
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({
        'success': False,
        'error': 'Endpoint not found'
    }), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({
        'success': False,
        'error': 'Internal server error'
    }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
