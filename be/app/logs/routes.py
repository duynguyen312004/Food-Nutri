from flask import Blueprint, request, jsonify, g
from auth.decorators import firebase_required
from logs.services import create_exercise_log, create_meal_log, create_water_log, get_aggregated_logs, get_recent_logs_for_user, delete_meal_log, delete_water_log, delete_exercise_log, update_meal_quantity
from datetime import datetime, date
from extensions import db

logs_bp = Blueprint('logs', __name__, url_prefix='/api/v1/logs')

@logs_bp.route("/recent", methods=['GET'])
@firebase_required()
def get_recent_logs():
    # 1. Parse ngày từ query param
    date_str = request.args.get('date')
    try:
        if date_str:
            # chuyển string "YYYY-MM-DD" thành date
            target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        else:
            target_date = date.today()
    except ValueError:
        return jsonify({"error": "Invalid date format, use YYYY-MM-DD"}), 400

    # 2. Lấy dữ liệu business
    try:
        uid = g.current_user.user_id
        data = get_recent_logs_for_user(uid, target_date)
        return jsonify({"data": data}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
@logs_bp.route('', methods=['GET'])
@firebase_required()
def list_logs():
    user_id = g.current_user.user_id
    date_str = request.args.get('date')
    if not date_str:
        return jsonify({'msg': 'Missing date param'}), 400
    try:
        query_date = datetime.strptime(date_str, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({
            'msg' : 'Invalid date format, expected YYYY-MM-DD'
        }), 400
    logs = get_aggregated_logs(user_id, query_date)
    return jsonify(logs), 200

@logs_bp.route('', methods=['POST'])
@firebase_required()
def create_log():
    """
    Ghi nhật ký (meal, water, exercise)
    Body:
    {
      "type": "water" | "meal" | "exercise",
      "timestamp": "...",
      "data": {...}
    }
    """
    data = request.get_json()
    if not data:
        return jsonify({"error": "Missing body"}), 400

    try:
        log_type = data["type"]
        timestamp = datetime.fromisoformat(data["timestamp"])
        payload = data["data"]
        user_id = g.current_user.user_id

        if log_type == "water":
            create_water_log(user_id, timestamp, payload)

        elif log_type == "meal":
            create_meal_log(user_id, timestamp, payload)

        elif log_type == "exercise":
            create_exercise_log(user_id, timestamp, payload)

        else:
            return jsonify({"error": "Unsupported log type"}), 400

        db.session.commit()
        return jsonify({"message": f"{log_type} log created"}), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500
    
@logs_bp.route('/<log_type>/<int:log_id>', methods=['DELETE'])
@firebase_required()
def delete_log(log_type, log_id):
    try:
        user_id = g.current_user.user_id

        if log_type == 'meal':
            delete_meal_log(log_id, user_id)

        elif log_type == 'water':
            delete_water_log(log_id, user_id)

        elif log_type == 'exercise':
            delete_exercise_log(log_id, user_id)

        else:
            return jsonify({'error': 'Unsupported log type'}), 400

        db.session.commit()
        return jsonify({'message': 'Log deleted'}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500
    
#cap nhat quantity meal log
@logs_bp.route('/meal/<int:log_id>', methods=['PATCH'])
@firebase_required()
def update_meal_log(log_id):
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Missing request body'}), 400

    quantity = data.get('quantity')
    timestamp_str = data.get('timestamp')

    if quantity is None or timestamp_str is None:
        return jsonify({'error': 'Missing quantity or timestamp'}), 400

    try:
        timestamp = datetime.fromisoformat(timestamp_str)
        user_id = g.current_user.user_id

        update_meal_quantity(log_id, quantity, user_id)

        db.session.commit()
        return jsonify({'message': 'Meal log updated successfully'}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500
