<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];
$input = getJsonInput();

$mealTime = trim($input['meal_time'] ?? 'Breakfast'); // Breakfast, Morning Snack, Lunch, Evening Snack, Dinner
$foodId = !empty($input['food_item_id']) ? intval($input['food_item_id']) : null;
$customName = trim($input['custom_name'] ?? '');
$quantity = floatval($input['quantity'] ?? 1.0);
$loggedDate = !empty($input['logged_date']) ? $input['logged_date'] : date('Y-m-d');

if ($quantity <= 0) $quantity = 1.0;

try {
    $pdo = getDBConnection();

    if ($foodId) {
        $itemStmt = $pdo->prepare("SELECT * FROM food_items WHERE id = :id LIMIT 1");
        $itemStmt->execute([':id' => $foodId]);
        $item = $itemStmt->fetch();

        if (!$item) {
            sendResponse(false, 'Selected food item not found', null, 404);
        }

        $name = $item['name'];
        $servingSize = $item['serving_size'];
        $cals = round(floatval($item['calories']) * $quantity, 1);
        $prot = round(floatval($item['protein']) * $quantity, 1);
        $carb = round(floatval($item['carbs']) * $quantity, 1);
        $fat = round(floatval($item['fat']) * $quantity, 1);
        $fiber = round(floatval($item['fiber']) * $quantity, 1);
    } else {
        if (empty($customName)) {
            sendResponse(false, 'Food name is required', null, 400);
        }
        $name = $customName;
        $servingSize = trim($input['serving_size'] ?? '1 serving');
        $cals = floatval($input['calories'] ?? 100) * $quantity;
        $prot = floatval($input['protein'] ?? 5) * $quantity;
        $carb = floatval($input['carbs'] ?? 15) * $quantity;
        $fat = floatval($input['fat'] ?? 3) * $quantity;
        $fiber = floatval($input['fiber'] ?? 2) * $quantity;
    }

    $insert = $pdo->prepare("
        INSERT INTO food_logs 
        (user_id, meal_time, food_item_id, custom_name, quantity, serving_size, calories, protein, carbs, fat, fiber, logged_date)
        VALUES 
        (:uid, :meal, :fid, :name, :qty, :serving, :cal, :prot, :carb, :fat, :fib, :date)
    ");
    $insert->execute([
        ':uid' => $userId,
        ':meal' => $mealTime,
        ':fid' => $foodId,
        ':name' => $name,
        ':qty' => $quantity,
        ':serving' => $servingSize,
        ':cal' => $cals,
        ':prot' => $prot,
        ':carb' => $carb,
        ':fat' => $fat,
        ':fib' => $fiber,
        ':date' => $loggedDate
    ]);

    $logId = $pdo->lastInsertId();

    sendResponse(true, 'Food logged successfully', [
        'id' => (int)$logId,
        'meal_time' => $mealTime,
        'name' => $name,
        'quantity' => $quantity,
        'calories' => $cals,
        'protein' => $prot,
        'carbs' => $carb,
        'fat' => $fat,
        'fiber' => $fiber,
        'logged_date' => $loggedDate
    ]);

} catch (Exception $e) {
    sendResponse(false, 'Failed to log food: ' . $e->getMessage(), null, 500);
}
