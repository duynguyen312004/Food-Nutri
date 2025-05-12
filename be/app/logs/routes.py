from flask import Blueprint, request, jsonify, g
from auth.decorators import firebase_required
from logs.services import get_aggregated_logs, get_recent_logs_for_user
from datetime import datetime, date

logs_bp = Blueprint('logs', __name__, url_prefix='/api/v1/logs')

@logs_bp.route("/recent", methods=['GET'])
@firebase_required()
def get_recent_logs():
    """
    Lấy các nhật ký gần đây của user theo ngày (mặc định là hôm nay)
    Query param: ?date=YYYY-MM-DD
    """
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