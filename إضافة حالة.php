<!DOCTYPE html>
<html lang="ar">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>إضافة حالة</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <style>
        body { font-family: 'Cairo', sans-serif; direction: rtl; margin: 0; padding: 0; }
        .form-container { max-width: 600px; margin: auto; padding: 20px; border: 1px solid #ddd; border-radius: 10px; box-shadow: 0 0 10px rgba(0, 0, 0, 0.1); }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: block; margin-bottom: 5px; font-weight: bold; }
        .form-group input, .form-group select { width: 100%; padding: 10px; font-size: 16px; border: 1px solid #ddd; border-radius: 5px; box-sizing: border-box; }
        .form-footer { display: flex; justify-content: space-between; align-items: center; }
        .form-footer button { padding: 10px 20px; font-size: 16px; border: none; border-radius: 5px; cursor: pointer; }
        .form-footer button.save-btn { background-color: #4CAF50; color: white; }
        .form-footer button.cancel-btn { background-color: #f44336; color: white; }
    </style>
</head>
<body>

<?php
require __DIR__ . '/vendor/autoload.php'; // Include Firebase autoload

use Kreait\Firebase\Factory;

// Initialize Firebase Firestore
$factory = (new Factory)->withServiceAccount('C:\wamp64\www\البروالاحسان/serviceAccountKey.json');
$firestore = $factory->createFirestore();
$database = $firestore->database();

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Get form data
    $data = [
        'name' => $_POST['name'] ?? null,
        'location' => $_POST['address'] ?? null,
        'age' => isset($_POST['age']) ? (int)$_POST['age'] : null,
        'social_status' => $_POST['marital-status'] ?? null,
        'source' => $_POST['source'] ?? null,
        'income' => isset($_POST['income']) ? (float)$_POST['income'] : null,
        'family_id' => isset($_POST['family-members']) ? (int)$_POST['family-members'] : null,
        'ID_Number' => $_POST['id-number'] ?? null,
        'number' => $_POST['phone-number'] ?? null,
        'insurance_number' => $_POST['insurance-number'] ?? null,
        'academic_level' => $_POST['academic-level'] ?? null,
        'event_measure' => $_POST['event-measure'] ?? null,
        'device_measure' => $_POST['device-measure'] ?? null,
        'area_id' => isset($_POST['area_id']) ? (int)$_POST['area_id'] : null,
    ];

    try {
        // Add document to Firestore
        $database->collection('cases')->add($data);

        echo "<p style='color: green; text-align: center;'>تم حفظ الحالة بنجاح.</p>";
    } catch (Exception $e) {
        echo "<p style='color: red; text-align: center;'>خطأ: " . $e->getMessage() . "</p>";
    }
}
?>

<div class="form-container">
    <h2>إضافة حالة</h2>
    <form action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]); ?>" method="POST">
        <input type="hidden" name="area_id" value="<?php echo isset($_GET['id']) ? (int)$_GET['id'] : ''; ?>">

        <div class="form-group">
            <label for="name">الاسم</label>
            <input type="text" id="name" name="name" placeholder="أدخل الاسم" required>
        </div>
        <div class="form-group">
            <label for="address">العنوان</label>
            <input type="text" id="address" name="address" placeholder="أدخل العنوان">
        </div>
        <div class="form-group">
            <label for="age">السن</label>
            <input type="number" id="age" name="age" placeholder="أدخل السن">
        </div>
        <div class="form-group">
            <label for="marital-status">الحالة الاجتماعية</label>
            <input type="text" id="marital-status" name="marital-status" placeholder="أدخل الحالة الاجتماعية">
        </div>
        <div class="form-group">
            <label for="source">المصدر</label>
            <input type="text" id="source" name="source" placeholder="أدخل المصدر">
        </div>
        <div class="form-group">
            <label for="income">الدخل</label>
            <input type="number" id="income" name="income" placeholder="أدخل الدخل">
        </div>
        <div class="form-group">
            <label for="family-members">عدد أعضاء الأسرة</label>
            <input type="number" id="family-members" name="family-members" placeholder="أدخل عدد أعضاء الأسرة">
        </div>
        <div class="form-group">
            <label for="id-number">الرقم القومي</label>
            <input type="text" id="id-number" name="id-number" placeholder="أدخل الرقم القومي">
        </div>
        <div class="form-group">
            <label for="phone-number">رقم هاتف</label>
            <input type="tel" id="phone-number" name="phone-number" placeholder="أدخل رقم الهاتف">
        </div>
        <div class="form-group">
            <label for="insurance-number">رقم التأمين الذي ينتمي لها</label>
            <input type="text" id="insurance-number" name="insurance-number" placeholder="أدخل رقم التأمين">
        </div>
        <div class="form-group">
            <label for="academic-level">المرحلة الدراسية</label>
            <input type="text" id="academic-level" name="academic-level" placeholder="أدخل المرحلة الدراسية">
        </div>
        <div class="form-group">
            <label for="event-measure">مقاس الملابس</label>
            <input type="text" id="event-measure" name="event-measure" placeholder="أدخل مقاس الحدث">
        </div>
        <div class="form-group">
            <label for="device-measure">مقاس جهاز العوسة</label>
            <input type="text" id="device-measure" name="device-measure" placeholder="أدخل مقاس جهاز العوسة">
        </div>
        <div class="form-footer">
            <button type="button" class="cancel-btn" onclick="window.history.back();">إلغاء</button>
            <button type="submit" class="save-btn">حفظ</button>
        </div>
    </form>
</div>

</body>
</html>