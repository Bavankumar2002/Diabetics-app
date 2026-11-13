<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];

try {
    $pdo = getDBConnection();
    $stmt = $pdo->prepare("
        SELECT id, role, message, DATE_FORMAT(created_at, '%h:%i %p') as time 
        FROM ai_chat_history 
        WHERE user_id = :uid 
        ORDER BY created_at ASC
    ");
    $stmt->execute([':uid' => $userId]);
    $history = $stmt->fetchAll();

    sendResponse(true, 'Chat history loaded', [
        'count' => count($history),
        'history' => $history
    ]);

} catch (Exception $e) {
    sendResponse(false, 'Failed to fetch chat history: ' . $e->getMessage(), null, 500);
}
