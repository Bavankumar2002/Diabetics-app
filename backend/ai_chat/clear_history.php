<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];

try {
    $pdo = getDBConnection();
    $stmt = $pdo->prepare("DELETE FROM ai_chat_history WHERE user_id = :uid");
    $stmt->execute([':uid' => $userId]);

    sendResponse(true, 'Chat history cleared successfully');

} catch (Exception $e) {
    sendResponse(false, 'Failed to clear chat history: ' . $e->getMessage(), null, 500);
}
