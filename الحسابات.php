<?php

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "berwehsan";

// Create connection to the MySQL database
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Fetch account data from the database
$sql = "SELECT account_type, balance, id FROM accounting_job"; // Replace 'accounts' with your actual table name
$result = $conn->query($sql);
?>

<!DOCTYPE html>
<html lang="ar">
<head>
    <meta charset="utf-8">
    <meta content="width=device-width, initial-scale=1.0" name="viewport">
    <title>الحسابات</title>
    <style>
        body {
            font-family: 'Cairo', sans-serif;
            margin: 0;
            padding: 0;
            direction: rtl;
        }
        .top-bar {
            background-color: #000;
            color: #fff;
            padding: 10px 0;
            text-align: center;
            font-size: 14px;
        }
        .header {
            background-color: #fff;
            padding: 20px 0;
            text-align: center;
            border-bottom: 1px solid #ddd;
        }
        .header img {
            max-height: 50px;
            margin: 0 10px;
        }
        .header .social-icons {
            margin-top: 10px;
        }
        .header .social-icons i {
            margin: 0 5px;
            color: #000;
        }
        .navbar {
            background-color: #fff;
            padding: 10px 0;
            text-align: center;
            border-bottom: 1px solid #ddd;
        }
        .navbar a {
            margin: 0 15px;
            color: #000;
            text-decoration: none;
            font-size: 16px;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            padding: 20px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        table, th, td {
            border: 1px solid #ddd;
        }
        th, td {
            padding: 12px;
            text-align: right;
        }
        th {
            background-color: #f2f2f2;
        }
        button {
            padding: 10px 20px;
            background-color: #3498db;
            color: white;
            border: none;
            cursor: pointer;
            border-radius: 4px;
        }
        button:hover {
            background-color: #2980b9;
        }
    </style>
</head>
<body>

<div class="top-bar">
    تعمل بإشرافه المركز الوطني لتنمية القطاع غير الربحي ، مصنفة بقدم (75)
</div>

<div class="header">
    <img alt="Logo 1" height="50" src="photo.png" width="100"/>
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
    <a href="الحسابات.php">الحسابات</a>
    <a href="الاطعام.php">الاطعام</a>
    <a href="تقارير.php">تقارير</a>
    <a href="خط سير.php">خط سير</a>
</div>

<div class="container">
    <h2>مراجعة و تسجيل الحسابات</h2>
    
    <table>
        <tr>
            <th>الجهة</th>
            <th>رصيد الحساب</th>
            <th>الإجراءات</th>
        </tr>
        <?php
        // Check if the query returns any results
        if ($result->num_rows > 0) {
            // Loop through the rows of data and display them
            while($row = $result->fetch_assoc()) {
                echo "<tr>";
                echo "<td>" . htmlspecialchars($row["account_type"]) . "</td>";
                echo "<td>" . number_format($row["balance"]) . "</td>";
                echo "<td>
                        <a href='withdrawالحسابات.php?id=" . $row["id"] . "' class='button'>تسجيل سحب</a>
                        <a href='depositالحسابات.php?id=" . $row["id"] . "' class='button'>تسجيل إيداع</a>
                        <a href='reportالحسابات.php?id=" . $row["id"] . "' class='button'>تقرير</a>
                    </td>";
                echo "</tr>";
            }
        } else {
            echo "<tr><td colspan='3'>لا توجد بيانات</td></tr>";
        }

        // Close the connection
        $conn->close();
        ?>
    </table>
</div>

</body>
</html>
