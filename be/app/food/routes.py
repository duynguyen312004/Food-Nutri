from sqlite3 import IntegrityError
import traceback

import requests
from extensions import db
from flask import Blueprint, g, jsonify, request
from auth.decorators import firebase_required
from food.services import (
    create_custom_food_service,
    create_recipe_service,
    delete_custom_food_service,
    get_my_foods,
    search_food_items,
    update_custom_food_service
)
from food.models import FoodItem

# Blueprint định nghĩa các route bắt đầu với /api/v1/foods
food_bp = Blueprint('food', __name__, url_prefix='/api/v1/foods')

# --- ROUTES ---

@food_bp.route('/<int:food_id>', methods=['GET'])
@firebase_required()
def get_food_by_id(food_id):
    """
    API lấy chi tiết 1 món ăn theo ID.
    Chỉ dùng để đọc dữ liệu món ăn.
    """
    food = FoodItem.query.get(food_id)
    if not food:
        return jsonify({'error': 'Food item not found'}), 404
    from food.services import food_to_dict
    return jsonify(food_to_dict(food))

@food_bp.route('/', methods=['GET'])
@firebase_required()
def search_foods():
    """
    API tìm kiếm món ăn theo tên (có hỗ trợ bỏ dấu).
    Nếu không truyền `query`, trả về mảng rỗng.
    """
    query = request.args.get('query', '').strip()
    user_id = g.current_user.user_id
    if not query:
        return jsonify([])
    foods = search_food_items(query, user_id)
    from food.services import food_to_dict
    return jsonify([food_to_dict(f) for f in foods])

@food_bp.route('/create', methods=['POST'])
@firebase_required()
def create_custom_food():
    """
    API tạo món ăn thủ công (Custom Food).
    Nhận dữ liệu dạng multipart/form-data.
    Có thể upload ảnh.
    """
    try:
        user_id = g.current_user.user_id
        form_data = request.form
        image_file = request.files.get('image')
        food = create_custom_food_service(form_data, image_file, user_id)
        from food.services import food_to_dict
        return jsonify(food_to_dict(food)), 200
    except Exception as e:
        traceback.print_exc()
        return jsonify({'error': str(e)}), 400

@food_bp.route('/recipes', methods=['POST'])
@firebase_required()
def create_recipe():
    """
    API tạo công thức món ăn (Recipe).
    Gửi dữ liệu multipart/form-data với:
    - name, serving_size, unit, ingredients (JSON string), optional: image
    """
    try:
        form_data = request.form
        image_file = request.files.get('image')
        user_id = g.current_user.user_id

        recipe_dict = create_recipe_service(form_data, image_file, user_id)
        return jsonify(recipe_dict), 201
    except Exception as e:
        traceback.print_exc()
        return jsonify({'error': str(e)}), 400

@food_bp.route('/my-foods', methods=['GET'])
@firebase_required()
def my_foods():
    """
    API lấy danh sách món tự tạo của người dùng.
    """
    user_id = g.current_user.user_id
    limit = int(request.args.get('limit', 10))
    result = get_my_foods(user_id, limit)
    return jsonify(result)

@food_bp.route('/<int:food_id>/update', methods=['PUT'])
@firebase_required()
def update_custom_food(food_id):
    """
    API cập nhật món ăn custom (chỉ user tạo mới được sửa).
    """
    try:
        user_id = g.current_user.user_id
        form_data = request.form
        image_file = request.files.get('image')
        food = update_custom_food_service(food_id, form_data, image_file, user_id)
        from food.services import food_to_dict
        return jsonify(food_to_dict(food)), 200
    except Exception as e:
        traceback.print_exc()
        return jsonify({'error': str(e)}), 400

@food_bp.route('/<int:food_id>/delete', methods=['DELETE'])
@firebase_required()
def delete_custom_food(food_id):
    try:
        user_id = g.current_user.user_id
        delete_custom_food_service(food_id, user_id)
        return jsonify({'message': 'Xoá thành công'}), 200
    except IntegrityError as e:
        # Bắt lỗi FK và trả về message đặc biệt cho FE nhận diện
        db.session.rollback()
        if 'foreign key constraint' in str(e).lower():
            return jsonify({'error': 'cannot_delete_used_food'}), 400
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        traceback.print_exc()
        return jsonify({'error': str(e)}), 400
    
@food_bp.route('/recipes/<int:recipe_id>/ingredients', methods=['GET'])
@firebase_required()
def get_recipe_ingredients(recipe_id):
    """
    API trả về danh sách nguyên liệu của 1 recipe cụ thể.
    """
    try:
        user_id = g.current_user.user_id
        from food.services import get_recipe_ingredients_service
        ingredients = get_recipe_ingredients_service(recipe_id, user_id)
        return jsonify(ingredients), 200
    except Exception as e:
        traceback.print_exc()
        return jsonify({'error': str(e)}), 400


@food_bp.route('/recipes/<int:recipe_id>', methods=['PUT'])
@firebase_required()
def update_recipe(recipe_id):
    """
    API cập nhật công thức món ăn.
    """
    try:
        user_id = g.current_user.user_id
        form_data = request.form
        image_file = request.files.get('image')
        from food.services import update_recipe_service
        updated = update_recipe_service(recipe_id, form_data, image_file, user_id)
        return jsonify(updated), 200
    except Exception as e:
        traceback.print_exc()
        return jsonify({'error': str(e)}), 400

@food_bp.route('/favorites', methods=['POST'])
@firebase_required()
def get_favorite_foods():
    """
    API lấy danh sách món ăn yêu thích theo list id.
    Body JSON: { "favorite_ids": [1,2,3,4] }
    """
    try:
        user_id = g.current_user.user_id
        data = request.get_json()
        favorite_ids = data.get("favorite_ids", [])
        from food.services import get_favorite_foods_service
        foods = get_favorite_foods_service(favorite_ids, user_id)
        return jsonify(foods), 200
    except Exception as e:
        import traceback; traceback.print_exc()
        return jsonify({'error': str(e)}), 400