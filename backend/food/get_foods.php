<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();

$q = trim($_GET['q'] ?? '');
$slot = trim($_GET['meal_slot'] ?? '');
$diet = trim($_GET['diet_type'] ?? '');
$lowCarb = isset($_GET['low_carb']) && $_GET['low_carb'] == '1';
$highFiber = isset($_GET['high_fiber']) && $_GET['high_fiber'] == '1';
$highProtein = isset($_GET['high_protein']) && $_GET['high_protein'] == '1';

try {
    $pdo = getDBConnection();
    $where = ["1=1"];
    $params = [];

    if (!empty($q)) {
        $where[] = "(name LIKE :q1 OR category LIKE :q2 OR description LIKE :q3)";
        $params[':q1'] = "%$q%";
        $params[':q2'] = "%$q%";
        $params[':q3'] = "%$q%";
    }
    if (!empty($slot)) {
        $where[] = "meal_slot = :slot";
        $params[':slot'] = $slot;
    }
    if (!empty($diet) && strtolower($diet) !== 'all') {
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

    $sql = "SELECT * FROM food_items WHERE " . implode(' AND ', $where) . " ORDER BY name ASC";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $foods = $stmt->fetchAll();

    sendResponse(true, 'Foods retrieved', [
        'count' => count($foods),
        'items' => $foods
    ]);

} catch (Exception $e) {
    sendResponse(false, 'Failed to retrieve foods: ' . $e->getMessage(), null, 500);
}
