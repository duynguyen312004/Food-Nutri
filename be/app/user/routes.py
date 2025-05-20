from flask import Blueprint, json, request, jsonify, g
from sqlalchemy import func
from auth.decorators import firebase_required
from user.services import complete_initial_setup, upsert_profile, upsert_settings, compute_user_metrics
from user.models import User, UserProfile, UserSettings, WeightLog, Goal
from datetime import datetime, date as DateType

user_bp = Blueprint('user', __name__, url_prefix='/api/v1/users')

@user_bp.route('/profile', methods=['GET', 'PUT'])
@firebase_required()
def profile():
    """
    GET: Lấy thông tin người dùng
    PUT: Cập nhật thông tin người dùng
    """
    uid = g.current_user.user_id
    if request.method == 'GET':
        prof = UserProfile.query.get(uid)
        return jsonify({
            'first_name': prof.first_name if prof else None,
            'last_name': prof.last_name if prof else None,
            'date_of_birth': prof.date_of_birth.isoformat() if prof and prof.date_of_birth else None,
            'gender': prof.gender if prof else None,
            'height_cm': float(prof.height_cm) if prof and prof.height_cm else None
        }), 200

    # PUT
    data = request.get_json()
    prof = upsert_profile(uid, data)
    return jsonify({
        'first_name': prof.first_name,
        'last_name': prof.last_name,
        'date_of_birth': prof.date_of_birth.isoformat() if prof.date_of_birth else None,
        'gender': prof.gender,
        'height_cm': float(prof.height_cm) if prof.height_cm else None
    }), 201

@user_bp.route('/settings', methods=['GET', 'PUT'])
@firebase_required()
def settings():
    """
    GET: Lấy thông tin cài đặt người dùng
    PUT: Cập nhật thông tin cài đặt người dùng
    """
    uid = g.current_user.user_id
    if request.method == 'GET':
        sett = UserSettings.query.get(uid)
        return jsonify({ field: getattr(sett, field) for field in (
            'locale', 'timezone', 'weight_unit', 'energy_unit',
            'default_target_calories', 'drink_water_reminder', 'meal_reminder'
        ) })

    # PUT
    data = request.get_json()
    sett = upsert_settings(uid, data)
    return jsonify({ field: getattr(sett, field) for field in (
        'locale', 'timezone', 'weight_unit', 'energy_unit',
        'default_target_calories', 'drink_water_reminder', 'meal_reminder'
    ) }), 201
@user_bp.route('/setup', methods=['POST'])
@firebase_required()
def setup():
    uid = g.current_user.user_id
    data = request.get_json()
    prof, wl, goal, sett = complete_initial_setup(uid, data)
    return jsonify({
        'profile': {
            'first_name': prof.first_name,
            'last_name': prof.last_name,
            'date_of_birth': prof.date_of_birth.isoformat() if prof.date_of_birth else None,
            'gender': prof.gender,
            'height_cm': float(prof.height_cm)
        },
        'initialWeightLog': {
            'weight_kg': float(wl.weight_kg) if wl else None,
            'logged_at': wl.logged_at.isoformat() if wl else None
        },
        'goal': {
            'goal_id': goal.goal_id,
            'target_value': float(goal.target_value),
            'goal_direction': goal.goal_direction,
            'duration_weeks': goal.duration_weeks,
            'weekly_rate': float(goal.weekly_rate),
            'start_date': goal.start_date.isoformat()
        },
        'settings': {
            'locale': sett.locale,
            'timezone': sett.timezone,
            'weight_unit': sett.weight_unit,
            'energy_unit': sett.energy_unit,
            'default_target_calories': sett.default_target_calories,
            'drink_water_reminder': sett.drink_water_reminder,
            'meal_reminder': sett.meal_reminder,
        },
    }), 201


@user_bp.route('/metrics', methods=['GET'])
@firebase_required()
def metrics():
    uid = g.current_user.user_id
    prof = UserProfile.query.get(uid)

    # 1) Parse ngày truyền lên (yyyy-MM-dd). Nếu không có, dùng hôm nay.
    date_str = request.args.get('date', None)
    # Khởi trước for_date để chắc chắn nó luôn tồn tại
    for_date = DateType.today()
    if date_str:
        try:
            for_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD'}), 400

    # 3) Lấy log cân nặng gần nhất <= for_date
    wl = (WeightLog.query
          .filter_by(user_id=uid)
          .filter(func.date(WeightLog.logged_at) <= for_date)
          .order_by(WeightLog.logged_at.desc())
          .first())

    data = {
        'current_weight_kg': wl.weight_kg if wl else 0,
        'goal_direction': Goal.query.filter_by(user_id=uid).first().goal_direction,
        'weekly_rate': Goal.query.filter_by(user_id=uid).first().weekly_rate,
    }

    # 4) Tính metrics
    raw = compute_user_metrics(uid, data, prof, for_date)

    # 5) Normalize macros
    macros_raw = raw.get('macros', {})
    macros_cons_raw = raw.get('macros_consumed', {})
    macros_consumed = {
    'protein': macros_cons_raw.get('protein_g', 0),
    'carbs':   macros_cons_raw.get('carbs_g',   0),
    'fat':     macros_cons_raw.get('fat_g',     0),
    }
    macros = {
        'protein': macros_raw.get('protein_g', 0),
        'carbs':   macros_raw.get('carbs_g',   0),
        'fat':     macros_raw.get('fat_g',     0),
    }
    result = {
        'bmi':    raw.get('bmi', 0),
        'bmr':    raw.get('bmr', 0),
        'tdee':   raw.get('tdee', 0),
        'target_calories': raw.get('target_calories', 0),
        'macros': macros,
        'macros_consumed': macros_consumed,
        'remaining_calories': raw.get('remaining_calories', 0),
        'calories_burned': raw['calories_burned'],
        'calories_consumed': raw['calories_consumed'],
        'water_intake_ml': raw['water_intake_ml']
    }
    return jsonify(result), 200
@user_bp.route('/goals', methods=['GET'])
@firebase_required()
def goals():
    """
    GET: Lấy mục tiêu weight hiện tại của user
    """
    uid = g.current_user.user_id
    goal = Goal.query.filter_by(user_id=uid).order_by(Goal.created_at.desc()).first()
    if not goal:
        return jsonify({'error': 'Goal not found'}), 404

    return jsonify({
        'goal_id':       goal.goal_id,
        'target_value':  float(goal.target_value),
        'goal_direction': goal.goal_direction,
        'duration_weeks': goal.duration_weeks,
        'weekly_rate':   float(goal.weekly_rate),
        'start_date':    goal.start_date.isoformat(),
    }), 200
