<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();

$diet = trim($_GET['diet_type'] ?? 'All');
$lowCarb = isset($_GET['low_carb']) && $_GET['low_carb'] == '1';
$highFiber = isset($_GET['high_fiber']) && $_GET['high_fiber'] == '1';
$highProtein = isset($_GET['high_protein']) && $_GET['high_protein'] == '1';

try {
    $pdo = getDBConnection();
    $slots = ['Breakfast', 'Morning Snack', 'Lunch', 'Evening Snack', 'Dinner'];
    $result = [];

    foreach ($slots as $slot) {
        $where = ["meal_slot = :slot", "is_diabetes_friendly = 1"];
        $params = [':slot' => $slot];

        if ($diet !== 'All' && !empty($diet)) {
            $where[] = "diet_type = :diet";
            $params[':diet'] = $diet;
        }
        if ($lowCarb) {
            $where[] = "is_low_carb = 1";
        }
        if ($highFiber) {
            $where[] = "is_high_fiber = 1";
        }
        if ($highProtein) {
            $where[] = "is_high_protein = 1";
        }

        $sql = "SELECT * FROM food_items WHERE " . implode(' AND ', $where) . " ORDER BY calories ASC LIMIT 6";
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $result[$slot] = $stmt->fetchAll();
    }

    sendResponse(true, 'Meal suggestions loaded', [
        'disclaimer' => 'These suggestions are curated based on low glycemic index and balanced macro standards. Please consult with your dietitian or diabetologist to personalize portion sizes and carbohydrate limits for your specific regimen.',
        'suggestions' => $result
    ]);

} catch (Exception $e) {
    sendResponse(false, 'Failed to fetch meal suggestions: ' . $e->getMessage(), null, 500);
}
