from food.models import FoodItem
from sqlalchemy import or_
import unicodedata

def remove_vietnamese_accents(text):
    text = unicodedata.normalize('NFD', text)
    return ''.join([c for c in text if unicodedata.category(c) != 'Mn'])

def search_food_items(query):
    query_unsigned = remove_vietnamese_accents(query.lower())
    foods = FoodItem.query.filter(
        or_(
            FoodItem.name.ilike(f"%{query}%"),
            FoodItem.name_unsigned.ilike(f"%{query_unsigned}%")
        )
    ).limit(15).all()
    return foods
