<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];

$period = $_GET['period'] ?? 'week'; // today, week, month, year, all

try {
    $pdo = getDBConnection();

    // Get user target range
    $diabStmt = $pdo->prepare("SELECT target_glucose_min, target_glucose_max FROM diabetes_details WHERE user_id = :uid LIMIT 1");
    $diabStmt->execute([':uid' => $userId]);
    $targets = $diabStmt->fetch();
    $targetMin = floatval($targets['target_glucose_min'] ?? 70.0);
    $targetMax = floatval($targets['target_glucose_max'] ?? 140.0);

    $dateFilter = "";
    if ($period === 'today') {
        $dateFilter = "AND DATE(measured_at) = CURDATE()";
    } elseif ($period === 'week') {
        $dateFilter = "AND measured_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)";
    } elseif ($period === 'month') {
        $dateFilter = "AND measured_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)";
    } elseif ($period === 'year') {
        $dateFilter = "AND measured_at >= DATE_SUB(NOW(), INTERVAL 365 DAY)";
    }

    $query = "
        SELECT id, reading_value, meal_type, unit, measured_at, notes,
               DATE_FORMAT(measured_at, '%Y-%m-%d %H:%i') as formatted_date,
               DATE_FORMAT(measured_at, '%b %d, %h:%i %p') as display_date
        FROM glucose_readings 
        WHERE user_id = :uid $dateFilter 
        ORDER BY measured_at DESC
    ";
    $stmt = $pdo->prepare($query);
    $stmt->execute([':uid' => $userId]);
    $readings = $stmt->fetchAll();

    // Calculate analytics
    $totalCount = count($readings);
    $sum = 0;
    $minVal = 9999.0;
    $maxVal = 0.0;
    $inRangeCount = 0;
    $highCount = 0;
    $lowCount = 0;

    foreach ($readings as &$r) {
        $v = floatval($r['reading_value']);
        $sum += $v;
        if ($v < $minVal) $minVal = $v;
        if ($v > $maxVal) $maxVal = $v;

        if ($v < $targetMin) {
            $r['status'] = 'low';
            $lowCount++;
        } elseif ($v > $targetMax) {
            $r['status'] = 'high';
            $highCount++;
        } else {
            $r['status'] = 'normal';
            $inRangeCount++;
        }
        // Also provide mmol/L conversion
        $r['reading_mmol'] = round($v / 18.0182, 1);
    }

    $avg = $totalCount > 0 ? round($sum / $totalCount, 1) : 0;
    $inRangePercent = $totalCount > 0 ? round(($inRangeCount / $totalCount) * 100) : 0;

    sendResponse(true, 'Readings retrieved', [
        'period' => $period,
        'target_range' => [
            'min' => $targetMin,
            'max' => $targetMax
        ],
        'stats' => [
            'count' => $totalCount,
            'average' => $avg,
            'lowest' => $totalCount > 0 ? $minVal : 0,
            'highest' => $totalCount > 0 ? $maxVal : 0,
            'in_range_percentage' => $inRangePercent,
            'in_range_count' => $inRangeCount,
            'high_count' => $highCount,
            'low_count' => $lowCount
        ],
        'readings' => $readings
    ]);

} catch (Exception $e) {
    sendResponse(false, 'Failed to fetch glucose readings: ' . $e->getMessage(), null, 500);
}
