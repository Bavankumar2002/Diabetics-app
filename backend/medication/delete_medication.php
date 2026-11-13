<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];
$input = getJsonInput();
$id = intval($input['id'] ?? ($_GET['id'] ?? 0));

if ($id <= 0) {
    sendResponse(false, 'Medication ID is required', null, 400);
}

try {
    $pdo = getDBConnection();
    $stmt = $pdo->prepare("UPDATE medication SET is_active = 0 WHERE id = :id AND user_id = :uid");
    $stmt->execute([':id' => $id, ':uid' => $userId]);

    if ($stmt->rowCount() > 0) {
        sendResponse(true, 'Medication removed successfully');
    } else {
        sendResponse(false, 'Medication not found or unauthorized', null, 404);
    }
} catch (Exception $e) {
    sendResponse(false, 'Failed to remove medication: ' . $e->getMessage(), null, 500);
}
