from flask import Blueprint, jsonify
from auth.decorators import firebase_required
from food.models import FoodItem

food_bp = Blueprint('food', __name__, url_prefix='/api/v1/foods')

@food_bp.route('/<int:food_id>', methods=['GET'])
@firebase_required()
def get_food_by_id(food_id):
    food = FoodItem.query.get(food_id)
    if not food:
        return jsonify({'error': 'Food item not found'}), 404

    return jsonify({
        'food_item_id': food.food_item_id,
        'name': food.name,
        'calories': float(food.calories),
        'protein': float(food.protein_g),
        'carbs': float(food.carbs_g),
        'fat': float(food.fat_g),
        'serving_size': float(food.serving_size),
        'serving_unit': food.serving_unit,
        'is_custom': food.is_custom,
        'image_url': food.image_url,
    })
