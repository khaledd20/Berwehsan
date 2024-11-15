<?php
// Database connection setup
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "berwehsan";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Initialize variables
$area_id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
$searchQuery = "";

// Handle search functionality
if (isset($_GET['search']) && !empty($_GET['search'])) {
    $searchTerm = $conn->real_escape_string($_GET['search']);
    if (is_numeric($searchTerm)) {
        // Search by ID
        $searchQuery = " AND id LIKE '$searchTerm'";
    } else {
        // Search by name
        $searchQuery = " AND name LIKE '%$searchTerm%'";
    }
}

// Fetch cases with the specified area_id and search term
$sql = "SELECT * FROM cases WHERE area_id = $area_id $searchQuery";
$result = $conn->query($sql);
?>

<!DOCTYPE html>
<html lang="ar">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>عرض الحالات</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <style>
        body { font-family: 'Cairo', sans-serif; direction: rtl; margin: 0; padding: 0; }
        .container { max-width: 1200px; margin: auto; padding: 20px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; text-align: center; padding: 10px; }
        th { background-color: #f2f2f2; }
        .action-buttons a {
            padding: 5px 10px;
            margin: 2px;
            border-radius: 4px;
            color: #fff;
            font-size: 14px;
            text-decoration: none;
            display: inline-block;
        }
        .deactivate { background-color: #ff5722; }
        .delete { background-color: #f44336; }
        .edit { background-color: #2196f3; }
        .file { background-color: #00bcd4; }
        .search-container { text-align: center; margin-bottom: 20px; }
        .search-container input[type="text"] { padding: 5px; width: 300px; }
        .search-container button { padding: 5px 10px; }
    </style>
</head>
<body>

<div class="container">
    <h2>جميع الحالات</h2>

    <!-- Search Form -->
    <form method="GET" action="" class="search-container">
        <input type="text" name="search" placeholder="ابحث بالاسم أو الرقم" value="<?php echo isset($_GET['search']) ? htmlspecialchars($_GET['search']) : ''; ?>">
        <input type="hidden" name="id" value="<?php echo htmlspecialchars($area_id); ?>">
        <button type="submit">بحث</button>
    </form>

    <table>
        <thead>
            <tr>
                <th>رقم الحالة</th>
                <th>الاسم</th>
                <th>الحالة</th>
                <th>المقر</th>
                <th>الصندوق</th>
                <th>المنطقة</th>
                <th>الإجراءات</th>
            </tr>
        </thead>
        <tbody>
            <?php
            if ($result && $result->num_rows > 0) {
                // Output data for each row
                while ($row = $result->fetch_assoc()) {
                    echo "<tr>";
                    echo "<td>" . htmlspecialchars($row["id"]) . "</td>";
                    echo "<td>" . htmlspecialchars($row["name"]) . "</td>";
                    echo "<td>" . ($row["status"] ? "مفعل" : "غير مفعل") . "</td>";
                    echo "<td>" . htmlspecialchars($row["location"]) . "</td>";
                    echo "<td>" . htmlspecialchars($row["chest_id"]) . "</td>";
                    echo "<td>" . htmlspecialchars($row["area_id"]) . "</td>";
                    echo "<td class='action-buttons'>";
                    echo "<a href='ملف_الحالة.php?id=" . htmlspecialchars($row["id"]) . "' class='file'>ملف الحالة</a>";
                    echo "<a href='تعديل.php?id=" . htmlspecialchars($row["id"]) . "' class='edit'>تعديل</a>";
                    echo "<a href='delete_case.php?id=" . htmlspecialchars($row["id"]) . "' class='delete' onclick='return confirm(\"هل أنت متأكد من حذف هذه الحالة؟\");'>حذف</a>";
                    echo "<a href='deactivate_case.php?id=" . htmlspecialchars($row["id"]) . "' class='deactivate'>إلغاء تفعيل</a>";
                    echo "</td>";
                    echo "</tr>";
                }
            } else {
                echo "<tr><td colspan='7'>لا توجد حالات مرتبطة بهذه المنطقة</td></tr>";
            }
            ?>
        </tbody>
    </table>
</div>

</body>
</html>

<?php
// Close the database connection
$conn->close();
?>
