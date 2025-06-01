import os
import unicodedata
import uuid
from flask import current_app, json, request
from sqlalchemy import or_
from werkzeug.utils import secure_filename
from extensions import db
from food.models import FoodItem, FoodItemIngredient

# --- HELPER ---

def remove_vietnamese_accents(text):
    """
    Bỏ dấu tiếng Việt để tìm kiếm không dấu.
    """
    text = unicodedata.normalize('NFD', text)
    return ''.join([c for c in text if unicodedata.category(c) != 'Mn'])

def save_food_image(image_file):
    """
    Lưu ảnh món ăn và trả về URL ảnh.
    """
    if not image_file:
        return None
    filename = secure_filename(image_file.filename)
    ext = filename.rsplit('.', 1)[-1]
    unique_filename = f"{uuid.uuid4().hex}.{ext}"
    upload_folder = current_app.config.get('UPLOAD_FOLDER', 'static/uploads')
    os.makedirs(upload_folder, exist_ok=True)
    img_path = os.path.join(upload_folder, unique_filename)
    image_file.save(img_path)
    host = request.host_url.rstrip('/')
    return f'{host}/static/uploads/{unique_filename}'

def food_to_dict(food, is_recipe=None):
    """
    Chuẩn hoá object món ăn khi trả về FE.
    """
    if is_recipe is None and hasattr(food, 'is_recipe'):
        is_recipe = getattr(food, 'is_recipe', False)
    return {
        'food_item_id': food.food_item_id,
        'name': food.name,
        'is_recipe': is_recipe,
        'calories': float(food.calories),
        'protein': float(food.protein_g),
        'carbs': float(food.carbs_g),
        'fat': float(food.fat_g),
        'serving_size': float(food.serving_size),
        'serving_unit': food.serving_unit,
        'is_custom': food.is_custom,
        'image_url': food.image_url,
    }

# --- SERVICE ---

def search_food_items(query, user_id=None, limit=15):
    """
    Tìm kiếm món ăn theo tên hoặc không dấu.
    Bao gồm món mặc định và món custom của user.
    """
    query_unsigned = remove_vietnamese_accents(query.lower())
    filters = [
        or_(
            FoodItem.name.ilike(f"%{query}%"),
            FoodItem.name_unsigned.ilike(f"%{query_unsigned}%")
        )
    ]
    if user_id is not None:
        filters.append(
            or_(
                FoodItem.is_custom == False,
                (FoodItem.is_custom == True) & (FoodItem.created_by == user_id)
            )
        )
    foods = FoodItem.query.filter(*filters).limit(limit).all()
    return foods

def create_custom_food_service(form_data, image_file, user_id):
    """
    Tạo mới món ăn custom (user nhập tay).
    """
    name = form_data.get('name', '').strip()
    if not name:
        raise ValueError('Tên thực phẩm là bắt buộc')
    name_unsigned = remove_vietnamese_accents(name.lower())
    serving_unit = form_data.get('serving_unit', 'g')
    serving_size = float(form_data.get('serving_size', 100))
    calories = float(form_data.get('calories', 0))
    protein = float(form_data.get('protein', 0))
    fat = float(form_data.get('fat', 0))
    carbs = float(form_data.get('carbs', 0))
    is_custom = str(form_data.get('is_custom', 'true')).lower() == 'true'
    is_recipe = str(form_data.get('is_recipe', 'false')).lower() == 'true'

    image_url = save_food_image(image_file) if image_file else None

    food = FoodItem(
        name=name,
        name_unsigned=name_unsigned,
        serving_unit=serving_unit,
        serving_size=serving_size,
        calories=calories,
        protein_g=protein,
        fat_g=fat,
        carbs_g=carbs,
        is_custom=is_custom,
        is_recipe=is_recipe,
        image_url=image_url,
        created_by=user_id
    )
    db.session.add(food)
    db.session.commit()
    return food

def update_custom_food_service(food_id, form_data, image_file, user_id):
    """
    Cập nhật món ăn custom (chỉ cho phép user tạo).
    """
    food = FoodItem.query.get(food_id)
    if not food or not food.is_custom or food.created_by != user_id:
        raise PermissionError('Bạn không có quyền sửa món này')

    name = form_data.get('name', '').strip()
    if name:
        food.name = name
        food.name_unsigned = remove_vietnamese_accents(name.lower())
    food.serving_unit = form_data.get('serving_unit', food.serving_unit)
    food.serving_size = float(form_data.get('serving_size', food.serving_size))
    food.calories = float(form_data.get('calories', food.calories))
    food.protein_g = float(form_data.get('protein', food.protein_g))
    food.fat_g = float(form_data.get('fat', food.fat_g))
    food.carbs_g = float(form_data.get('carbs', food.carbs_g))
    if image_file:
        food.image_url = save_food_image(image_file)
    db.session.commit()
    return food

def delete_image_file(image_url):
    # Tùy cấu hình, bóc path ra từ url, ví dụ:
    if not image_url:
        return
    filename = image_url.split('/')[-1]
    upload_folder = current_app.config.get('UPLOAD_FOLDER', 'static/uploads')
    file_path = os.path.join(upload_folder, filename)
    # Không xóa nếu là ảnh mặc định
    if not filename.startswith('default') and os.path.exists(file_path):
        os.remove(file_path)

def delete_custom_food_service(food_id, user_id):
    food = FoodItem.query.get(food_id)
    if not food or not food.is_custom or food.created_by != user_id:
        raise PermissionError('Bạn không có quyền xoá món này')
    # Xoá ảnh nếu cần
    delete_image_file(food.image_url)
    db.session.delete(food)
    db.session.commit()


def create_recipe_service(form_data, image_file, user_id):
    """
    Tạo công thức món ăn (gồm nhiều nguyên liệu).
    """
    name = form_data.get('name', '').strip()
    if not name:
        raise ValueError('Tên món ăn là bắt buộc')
    serving_size = float(form_data.get('serving_size', 0))
    if serving_size <= 0:
        raise ValueError('Khẩu phần không hợp lệ')
    serving_unit = form_data.get('serving_unit', 'g')

    ingredients_raw = form_data.get('ingredients')
    if not ingredients_raw:
        raise ValueError('Phải có ít nhất 1 nguyên liệu')

    try:
        ingredients = json.loads(ingredients_raw)
    except:
        raise ValueError('Danh sách nguyên liệu không hợp lệ')

    image_url = save_food_image(image_file) if image_file else None

    recipe_data = {
        "name": name,
        "serving_size": serving_size,
        "serving_unit": serving_unit,
        "ingredients": ingredients,
        "image_url": image_url
    }

    return create_recipe_item(recipe_data, user_id)

def create_recipe_item(data, user_id):
    try:
        name = data['name'].strip()
        name_unsigned = remove_vietnamese_accents(name.lower())
        serving_size = float(data['serving_size'])
        serving_unit = data['serving_unit']
        image_url = data.get('image_url')

        recipe = FoodItem(
            name=name,
            name_unsigned=name_unsigned,
            serving_size=serving_size,
            serving_unit=serving_unit,
            calories=0,
            protein_g=0,
            carbs_g=0,
            fat_g=0,
            image_url=image_url,
            is_custom=True,
            is_recipe=True,
            created_by=user_id
        )
        db.session.add(recipe)
        db.session.flush()  # lấy ID

        # Bước 1: insert tất cả ingredient liên kết vào DB
        for ing in data['ingredients']:
            ingredient_id = ing['food_item_id']
            quantity = float(ing['quantity'])
            unit = ing.get('unit', 'g')
            ingredient = FoodItem.query.get(ingredient_id)
            if not ingredient:
                raise ValueError(f'Ingredient food_item_id={ingredient_id} không tồn tại.')
            if quantity <= 0:
                raise ValueError('Số lượng nguyên liệu phải > 0')
            fi_ing = FoodItemIngredient(
                recipe_id=recipe.food_item_id,
                ingredient_id=ingredient_id,
                quantity=quantity,
                unit=unit
            )
            db.session.add(fi_ing)
        
        db.session.flush()  # ensure all ingredients added!

        # Bước 2: tính tổng dinh dưỡng
        total_calories = total_protein = total_carbs = total_fat = 0.0
        for ing in data['ingredients']:
            ingredient_id = ing['food_item_id']
            quantity = float(ing['quantity'])
            ingredient = FoodItem.query.get(ingredient_id)
            if not ingredient:
                continue
            serving_size = float(ingredient.serving_size) if ingredient.serving_size else 1
            calories = float(ingredient.calories or 0)
            protein_g = float(ingredient.protein_g or 0)
            carbs_g = float(ingredient.carbs_g or 0)
            fat_g = float(ingredient.fat_g or 0)
            ratio = quantity / serving_size if serving_size else 1

            total_calories += calories * ratio
            total_protein  += protein_g * ratio
            total_carbs    += carbs_g * ratio
            total_fat      += fat_g * ratio

        recipe.calories  = total_calories
        recipe.protein_g = total_protein
        recipe.carbs_g   = total_carbs
        recipe.fat_g     = total_fat

        db.session.commit()
        return food_to_dict(recipe, is_recipe=True)

    except Exception as e:
        db.session.rollback()
        raise e


def get_recipe_ingredients_service(recipe_id, user_id):
    """
    Trả về danh sách nguyên liệu (bao gồm cả thông tin món ăn) của 1 recipe.
    """
    recipe = FoodItem.query.get(recipe_id)
    if not recipe or not recipe.is_custom or recipe.created_by != user_id:
        raise PermissionError('Không tìm thấy công thức hoặc không có quyền truy cập')

    from food.services import food_to_dict

    ingredients = FoodItemIngredient.query.filter_by(recipe_id=recipe_id).all()
    results = []
    for ing in ingredients:
        ingredient_food = FoodItem.query.get(ing.ingredient_id)
        if not ingredient_food:
            continue
        results.append({
            'food_item': food_to_dict(ingredient_food),
            'quantity': ing.quantity,
            'unit': ing.unit,
        })
    return results

def update_recipe_service(recipe_id, form_data, image_file, user_id):
    """
    Cập nhật công thức món ăn.
    """
    recipe = FoodItem.query.get(recipe_id)
    if not recipe or not recipe.is_recipe or recipe.created_by != user_id:
        raise PermissionError('Không có quyền cập nhật món này')

    name = form_data.get('name', '').strip()
    if not name:
        raise ValueError('Tên món ăn là bắt buộc')

    serving_size = float(form_data.get('serving_size', recipe.serving_size))
    serving_unit = form_data.get('serving_unit', recipe.serving_unit)
    ingredients_raw = form_data.get('ingredients')
    if not ingredients_raw:
        raise ValueError('Phải có danh sách nguyên liệu')

    try:
        ingredients = json.loads(ingredients_raw)
    except Exception:
        raise ValueError('Dữ liệu nguyên liệu không hợp lệ')

    if image_file:
        recipe.image_url = save_food_image(image_file)
    recipe.name = name
    recipe.name_unsigned = remove_vietnamese_accents(name.lower())
    recipe.serving_size = serving_size
    recipe.serving_unit = serving_unit

    # Xoá nguyên liệu cũ
    FoodItemIngredient.query.filter_by(recipe_id=recipe_id).delete()

    # Thêm lại nguyên liệu mới
    total_calories = total_protein = total_carbs = total_fat = 0.0
    for ing in ingredients:
        try:
            ingredient_id = int(ing['food_item_id'])
            quantity = float(ing['quantity'])
            unit = ing.get('unit', 'g')
        except Exception:
            raise ValueError('Dữ liệu nguyên liệu không hợp lệ')
        ingredient = FoodItem.query.get(ingredient_id)
        if not ingredient:
            continue
        fi_ing = FoodItemIngredient(
            recipe_id=recipe_id,
            ingredient_id=ingredient_id,
            quantity=quantity,
            unit=unit
        )
        db.session.add(fi_ing)

        # Tính dinh dưỡng
        ratio = quantity / float(ingredient.serving_size or 1)
        total_calories += float(ingredient.calories or 0) * ratio
        total_protein  += float(ingredient.protein_g or 0) * ratio
        total_carbs    += float(ingredient.carbs_g or 0) * ratio
        total_fat      += float(ingredient.fat_g or 0) * ratio

    recipe.calories = total_calories
    recipe.protein_g = total_protein
    recipe.carbs_g = total_carbs
    recipe.fat_g = total_fat

    db.session.commit()
    return food_to_dict(recipe, is_recipe=True)


def get_my_foods(user_id, limit=20):
    """
    Trả về danh sách món ăn mà user đã tự tạo (cả custom & recipe).
    """
    foods = FoodItem.query.filter(
        FoodItem.is_custom == True,
        FoodItem.created_by == user_id
    ).order_by(FoodItem.created_at.desc()).limit(limit).all()

    # Lấy danh sách ID món là công thức
    recipe_ids = set(
        r.recipe_id for r in FoodItemIngredient.query.with_entities(FoodItemIngredient.recipe_id).distinct()
    )

    results = []
    for food in foods:
        is_recipe = food.food_item_id in recipe_ids
        results.append(food_to_dict(food, is_recipe=is_recipe))
    return results
