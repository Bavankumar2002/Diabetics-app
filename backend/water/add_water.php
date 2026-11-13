<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];
$input = getJsonInput();

$amount = intval($input['amount_ml'] ?? 250);
$date = !empty($input['date']) ? $input['date'] : date('Y-m-d');

if ($amount <= 0) {
    sendResponse(false, 'Please provide a valid water amount in ml', null, 400);
}

try {
    $pdo = getDBConnection();
    $stmt = $pdo->prepare("
        INSERT INTO water_logs (user_id, amount_ml, logged_date)
        VALUES (:uid, :amount, :date)
    ");
    $stmt->execute([':uid' => $userId, ':amount' => $amount, ':date' => $date]);

    // Recalculate total
    $sumStmt = $pdo->prepare("SELECT COALESCE(SUM(amount_ml), 0) FROM water_logs WHERE user_id = :uid AND logged_date = :date");
    $sumStmt->execute([':uid' => $userId, ':date' => $date]);
    $total = intval($sumStmt->fetchColumn());

    sendResponse(true, "Added {$amount} ml water", [
        'added_ml' => $amount,
        'total_consumed_ml' => $total,
        'date' => $date
    ]);

} catch (Exception $e) {
    sendResponse(false, 'Failed to add water: ' . $e->getMessage(), null, 500);
}
