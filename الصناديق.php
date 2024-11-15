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

// Fetch data from the `chests` table
$sql = "SELECT * FROM chests ";
$result = $conn->query($sql);
?>

<!DOCTYPE html>
<html lang="ar">
<head>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Home Page</title>
    <style>
        body { font-family: 'Cairo', sans-serif; margin: 0; padding: 0; direction: rtl; }
        .top-bar { background-color: #000; color: #fff; padding: 10px 0; text-align: center; font-size: 14px; }
        .header { background-color: #fff; padding: 20px 0; text-align: center; border-bottom: 1px solid #ddd; }
        .header img { max-height: 50px; margin: 0 10px; }
        .navbar { background-color: #fff; padding: 10px 0; text-align: center; border-bottom: 1px solid #ddd; }
        .navbar a { margin: 0 15px; color: #000; text-decoration: none; font-size: 16px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        table, th, td { border: 1px solid #ddd; text-align: center; padding: 8px; }
        th { background-color: #f2f2f2; }
        .action-buttons a {
    padding: 5px 10px;
    margin: 0 5px;
    border-radius: 4px;
    color: #fff;
    font-size: 14px;
    text-decoration: none;
}
        .deactivate { background-color: #ff5722; }
        .delete { background-color: #f44336; }
        .edit { background-color: #2196f3; }
        .add-area { background-color: #4caf50; }
        .add-amount { background-color: #3f51b5; }
        .view-areas { background-color: #9c27b0; }
    </style>
    <script>
        function confirmDelete(id) {
    console.log("Delete function triggered for ID: " + id); // This will appear in the console if the function is triggered
    if (confirm("Are you sure you want to delete this item?")) {
        window.location.href = "delete.php?id=" + id;
    }
}

function editItem(id) {
    console.log("Edit function triggered for ID: " + id);
    window.location.href = "edit.php?id=" + id;
}

      </script>  
</head>
<body>
    <div class="top-bar">تعمل بإشرافه المركز الوطني لتنمية القطاع غير الربحي ، مصنفة بقدم (75)</div>
    <div class="header">
        <img src="photo.png" alt="Logo 1" height="50" width="100"/>
        <div class="social-icons">
            <i class="fab fa-facebook-f"></i>
            <i class="fab fa-twitter"></i>
            <i class="fab fa-instagram"></i>
            <i class="fab fa-youtube"></i>
        </div>
    </div>
    <div class="navbar">
        <a href="الرئيسية.php">الرئيسية</a>
        <a href="الصناديق.php">الصناديق</a>
        <a href="المناطق.php">المناطق</a>
        <a href="المخزون.php">المخزون</a>
        <a href="الحالات.php">الحالات</a>
        <a href="الحسابات.php">الحسابات</a>
        <a href="الاطعام.php">الاطعام</a>    
        <a href="تقارير.php">تقارير</a>
        <a href="خط سير.php">خط سير</a>
    </div>

    <div class="container">
        <h2>جميع الصناديق</h2>
        <table>
            <tr>
                <th>المعرف</th>
                <th>الصندوق</th>
                <th>الرصيد</th>
                <th>الحصة</th>
                <th>الإجراءات</th>
            </tr>
            <?php
            if ($result->num_rows > 0) {
                // Output data for each row 
                while($row = $result->fetch_assoc()) {
                    echo "<tr>";
                    echo "<td>" . $row["id"] . "</td>";
                    echo "<td>" . $row["name"] . "</td>";
                    echo "<td>" . $row["balance"] . "</td>";
                    echo "<td>" . $row["share"] . "</td>";
                    echo "<td class='action-buttons'>";
                    echo "<a href='الصناديق.php?id=" . $row["id"] . "' class='delete' onclick='return confirm(\"Are you sure you want to delete this item?\")'>حذف</a>";
                    echo "<a href='edit.php?id=" . $row["id"] . "' class='edit'>تعديل</a>";
                    echo "<a href='قبض الحالات.php?id=" . $row["id"] . "' class='add-amount'>إضافة قبض</a>";
                    echo "<a href='add_area.php?id=" . $row["id"] . "' class='add-area'>إضافة منطقة</a>";
                    echo "<a href='عرض الصندوق.php?id=" . $row["id"] . "' class='view-areas'>عرض الصندوق</a>";
                    echo "</td>";
                    echo "</tr>";
                }
            } else {
                echo "<tr><td colspan='6'>لا توجد بيانات</td></tr>";
            }
            $conn->close();
            ?>
        </table>
    </div>
</body>
</html>
