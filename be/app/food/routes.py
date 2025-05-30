import unicodedata
from flask import Blueprint, jsonify, request
from sqlalchemy import or_
from auth.decorators import firebase_required
from food.services import search_food_items
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

@food_bp.route('/', methods=['GET'])
@firebase_required()
def search_foods():
    query = request.args.get('query', '').strip()
    if not query:
        return jsonify([])
    foods = search_food_items(query)
    return jsonify([
        {
            'food_item_id': f.food_item_id,
            'name': f.name,
            'calories': float(f.calories),
            'protein': float(f.protein_g),
            'carbs': float(f.carbs_g),
            'fat': float(f.fat_g),
            'serving_size': float(f.serving_size),
            'serving_unit': f.serving_unit,
            'is_custom': f.is_custom,
            'image_url': f.image_url,
        } for f in foods
    ])