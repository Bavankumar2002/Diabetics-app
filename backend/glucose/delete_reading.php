<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];
$input = getJsonInput();
$readingId = intval($input['id'] ?? ($_GET['id'] ?? 0));

if ($readingId <= 0) {
    sendResponse(false, 'Reading ID is required', null, 400);
}

try {
    $pdo = getDBConnection();
    $stmt = $pdo->prepare("DELETE FROM glucose_readings WHERE id = :id AND user_id = :uid");
    $stmt->execute([':id' => $readingId, ':uid' => $userId]);

    if ($stmt->rowCount() > 0) {
        sendResponse(true, 'Glucose reading deleted successfully');
    } else {
        sendResponse(false, 'Reading not found or unauthorized', null, 404);
    }
} catch (Exception $e) {
    sendResponse(false, 'Failed to delete reading: ' . $e->getMessage(), null, 500);
}
