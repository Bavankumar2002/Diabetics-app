<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];
$date = $_GET['date'] ?? date('Y-m-d');

try {
    $pdo = getDBConnection();

    $goalStmt = $pdo->prepare("SELECT step_goal, exercise_goal_mins FROM user_profiles WHERE user_id = :uid LIMIT 1");
    $goalStmt->execute([':uid' => $userId]);
    $goals = $goalStmt->fetch();
    $stepGoal = intval($goals['step_goal'] ?? 8000);
    $exerciseGoal = intval($goals['exercise_goal_mins'] ?? 30);

    // Today's summary
    $sumStmt = $pdo->prepare("
        SELECT 
            COALESCE(SUM(steps), 0) as total_steps,
            COALESCE(SUM(duration_mins), 0) as total_duration,
            COALESCE(SUM(calories_burned), 0) as total_calories
        FROM activity_logs 
        WHERE user_id = :uid AND logged_date = :date
    ");
    $sumStmt->execute([':uid' => $userId, ':date' => $date]);
    $todaySummary = $sumStmt->fetch();

    // Today's list
    $listStmt = $pdo->prepare("
        SELECT id, activity_type, steps, duration_mins, calories_burned, 
               DATE_FORMAT(created_at, '%h:%i %p') as time
        FROM activity_logs 
        WHERE user_id = :uid AND logged_date = :date 
        ORDER BY created_at DESC
    ");
    $listStmt->execute([':uid' => $userId, ':date' => $date]);
    $activities = $listStmt->fetchAll();

    // 7-day history for activity chart
    $historyStmt = $pdo->prepare("
        SELECT logged_date, 
               COALESCE(SUM(steps), 0) as steps,
               COALESCE(SUM(calories_burned), 0) as calories,
               COALESCE(SUM(duration_mins), 0) as duration
        FROM activity_logs 
        WHERE user_id = :uid AND logged_date >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
        GROUP BY logged_date
        ORDER BY logged_date ASC
    ");
    $historyStmt->execute([':uid' => $userId]);
    $weeklyHistory = $historyStmt->fetchAll();

    sendResponse(true, 'Activity data loaded', [
        'date' => $date,
        'step_goal' => $stepGoal,
        'exercise_goal_mins' => $exerciseGoal,
        'today' => [
            'steps' => intval($todaySummary['total_steps']),
            'duration_mins' => intval($todaySummary['total_duration']),
            'calories_burned' => intval($todaySummary['total_calories']),
            'step_percentage' => min(100, round((intval($todaySummary['total_steps']) / max(1, $stepGoal)) * 100)),
        ],
        'activities' => $activities,
        'weekly_history' => $weeklyHistory
    ]);

} catch (Exception $e) {
    sendResponse(false, 'Failed to fetch activity: ' . $e->getMessage(), null, 500);
}
