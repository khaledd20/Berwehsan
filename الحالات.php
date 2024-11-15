<?php
require __DIR__ . '/vendor/autoload.php'; // Ensure the correct path to your autoload file

use Kreait\Firebase\Factory;

session_start();

// Initialize Firebase Firestore
$factory = (new Factory)->withServiceAccount('C:\wamp64\www\البروالاحسان\serviceAccountKey.json');
$firestore = $factory->createFirestore();
$database = $firestore->database();

// Handle Delete Request
if (isset($_POST['delete_id'])) {
    $idToDelete = $_POST['delete_id'];
    $casesCollection = $database->collection('cases');
    $document = $casesCollection->document($idToDelete);

    try {
        $document->delete();
        echo "<script>alert('تم حذف الحالة بنجاح!');</script>";
    } catch (Exception $e) {
        echo "<script>alert('حدث خطأ أثناء حذف الحالة: " . $e->getMessage() . "');</script>";
    }
}

// Handle Toggle Status Request
if (isset($_POST['toggle_id'])) {
    $idToToggle = $_POST['toggle_id'];
    $currentStatus = $_POST['current_status'];
    $newStatus = ($currentStatus === 'مفعل') ? 'غير مفعل' : 'مفعل';

    $casesCollection = $database->collection('cases');
    $document = $casesCollection->document($idToToggle);

    try {
        $document->update([
            ['path' => 'status', 'value' => $newStatus]
        ]);
        echo "<script>alert('تم تحديث حالة الحالة بنجاح!');</script>";
    } catch (Exception $e) {
        echo "<script>alert('حدث خطأ أثناء تحديث الحالة: " . $e->getMessage() . "');</script>";
    }
}

// Initialize search filters
$casesCollection = $database->collection('cases');
$query = $casesCollection;

if (isset($_GET['search'])) {
    $searchTerm = $_GET['search'];
    // Check if the search term is numeric (for ID search) or a string (for name search)
    if (is_numeric($searchTerm)) {
        $query = $query->where('id', '=', intval($searchTerm));
    } else {
        $query = $query->where('name', '=', $searchTerm);
    }
}

// Fetch all cases
$documents = $query->documents();
?>

<!DOCTYPE html>
<html lang="ar">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>جدول الحالات</title>
    <style>
        table {
            width: 100%;
            border-collapse: collapse;
        }
        table, th, td {
            border: 1px solid black;
        }
        th, td {
            padding: 10px;
            text-align: center;
        }
        .action-btn {
            padding: 5px 10px;
            margin: 2px;
            border-radius: 5px;
            cursor: pointer;
        }
        .edit { background-color: #007bff; color: white; }
        .delete { background-color: #dc3545; color: white; }
        .deactivate { background-color: #ffc107; color: white; }
    </style>
</head>
<body>
<center>
    <h1>جدول الحالات</h1>
</center>
<br>
<form method="GET" action="" style="text-align:center; margin-bottom: 20px;">
    <input type="text" name="search" placeholder="ابحث بالاسم أو الرقم" value="<?php echo isset($_GET['search']) ? $_GET['search'] : ''; ?>" style="padding: 5px; width: 300px;">
    <button type="submit" style="padding: 5px 10px;">بحث</button>
</form>
<br>
<table>
    <thead>
        <tr>
            <th>رقم الحالة</th>
            <th>الاسم</th>
            <th>الحالة</th>
            <th>المنطقة</th>
            <th>الإجراءات</th>
        </tr>
    </thead>
    <tbody>
        <?php
        if (!$documents->isEmpty()) {
            foreach ($documents as $document) {
                $data = $document->data();
                $id = $document->id();
                $name = $data['name'] ?? 'غير متوفر';
                $status = $data['status'] ?? 'غير متوفر';
                $region = $data['location'] ?? 'غير متوفر';

                echo "<tr id='row_$id'>";
                echo "<td>$id</td>";
                echo "<td>$name</td>";
                echo "<td id='status_$id'>$status</td>";
                echo "<td>$region</td>";
                echo "<td>
                    <form method='POST' style='display:inline;'>
                        <input type='hidden' name='delete_id' value='$id'>
                        <button type='submit' class='action-btn delete'>حذف</button>
                    </form>
                    <form method='POST' style='display:inline;'>
                        <input type='hidden' name='toggle_id' value='$id'>
                        <input type='hidden' name='current_status' value='$status'>
                        <button type='submit' class='action-btn deactivate'>" . ($status === 'مفعل' ? 'إلغاء تفعيل' : 'تفعيل') . "</button>
                    </form>
                    <a href='ملف_الحالة.php?id=$id' class='action-btn edit'>ملف الحالة</a>
                    <a href='تعديل.php?id=$id' class='action-btn edit'>تعديل</a>
                </td>";
                echo "</tr>";
            }
        } else {
            echo "<tr><td colspan='5'>لا توجد بيانات</td></tr>";
        }
        ?>
    </tbody>
</table>

</body>
</html>