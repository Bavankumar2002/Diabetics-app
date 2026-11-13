<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];

try {
    $pdo = getDBConnection();
    // Foreign keys have ON DELETE CASCADE
    $stmt = $pdo->prepare("DELETE FROM users WHERE id = :uid");
    $stmt->execute([':uid' => $userId]);

    sendResponse(true, 'Your account and all associated health records have been permanently deleted.');

} catch (Exception $e) {
    sendResponse(false, 'Failed to delete account: ' . $e->getMessage(), null, 500);
}
