from flask import Blueprint, request, jsonify, g
from exercise.models import ExerciseType
from exercise.services import create_exercise_log, fetch_exercise_types

exercise_bp = Blueprint('exercise', __name__, url_prefix='/api/v1/exercise')

@exercise_bp.route('', methods=['POST'])
@exercise_bp.route('', methods=['POST'])
def add_exercise_log():
    """
    Tạo bản ghi exercise mới cho user hiện tại.
    Body JSON phải có: exercise_type_id, duration_min
    """
    data = request.get_json() or {}
    ex_type_id = data.get('exercise_type_id')
    duration = data.get('duration_min')
    if ex_type_id is None or duration is None:
        return jsonify({'error': 'exercise_type_id và duration_min là bắt buộc'}), 400

    try:
        user_id = g.current_user.user_id
        log = create_exercise_log(user_id, ex_type_id, duration)
        return jsonify({
            'exercise_id': log.exercise_id,
            'exercise_type': log.exercise_type.name,
            'duration_min': log.duration_min,
            'calories_burned': float(log.calories_burned),
            'logged_at': log.logged_at.isoformat(),
        }), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@exercise_bp.route('/types', methods=['GET'])
def get_exercise_types():
    """
    Trả về danh sách các loại bài tập (id, name, mets, category)
    """
    types = fetch_exercise_types()
    return jsonify([
        {
            'id': t.exercise_type_id,
            'name': t.name,
            'mets': float(t.mets or 0),
            'category': t.category,
        }
        for t in types
    ]), 200