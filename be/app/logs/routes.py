from flask import Blueprint, request, jsonify, g
from auth.decorators import firebase_required
from logs.services import get_recent_logs_for_user
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