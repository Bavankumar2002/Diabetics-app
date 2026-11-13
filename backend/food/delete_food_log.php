<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];
$input = getJsonInput();
$id = intval($input['id'] ?? ($_GET['id'] ?? 0));

if ($id <= 0) {
    sendResponse(false, 'Log ID is required', null, 400);
}

try {
    $pdo = getDBConnection();
    $stmt = $pdo->prepare("DELETE FROM food_logs WHERE id = :id AND user_id = :uid");
    $stmt->execute([':id' => $id, ':uid' => $userId]);

    if ($stmt->rowCount() > 0) {
        sendResponse(true, 'Food log entry deleted');
    } else {
        sendResponse(false, 'Entry not found or unauthorized', null, 404);
    }
} catch (Exception $e) {
    sendResponse(false, 'Failed to delete food log: ' . $e->getMessage(), null, 500);
}
