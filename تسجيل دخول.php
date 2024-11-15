<?php 
require __DIR__ . '/vendor/autoload.php'; // Ensure this path points to the correct location of the autoload file

use Kreait\Firebase\Factory;

session_start();

// Initialize Firebase
$factory = (new Factory)->withServiceAccount('C:\wamp64\www\البروالاحسان\serviceAccountKey.json');
$firestore = $factory->createFirestore();
$database = $firestore->database();

// Query Firestore Data
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $fullName = $_POST['full_name']; // Assuming user inputs full_name to log in
    $password = $_POST['password'];  // Assuming a password is used

    try {
        // Reference the 'admins' collection
        $adminsCollection = $database->collection('admins');
        $query = $adminsCollection
            ->where('FullName', '=', $fullName)
            ->where('Password', '=', $password);
        $documents = $query->documents();

        if ($documents->isEmpty()) {
            echo "<p>اسم المستخدم أو كلمة المرور غير صحيحة.</p>";
        } else {
            foreach ($documents as $document) {
                $data = $document->data();

                // Authenticate the user
                $_SESSION["FullName"] = $data['FullName'];
                $_SESSION["Role"] = $data['Role'];
                $_SESSION["email"] = $data['email'];

                // Redirect to the dashboard
                header("Location: الحالات.php"); // Redirect to a dashboard page
                exit();
            }
        }
    } catch (Exception $e) {
        echo "<p>حدث خطأ: " . $e->getMessage() . "</p>";
    }
}
?>

<!DOCTYPE html>
<html lang="ar">
<head>
    <meta charset="utf-8">
    <title>تسجيل دخول</title>
    <link href="STYLEEE.css" rel="stylesheet">
</head>
<body>
<section class="login" id="login">
  <div class="head">
      <h1 class="company">تسجيل دخول</h1>
  </div>
  <p class="msg">مرحباً بكم في النظام الإلكتروني لجمعية البر والإحسان</p>
  <div class="form">
      <form action="تسجيل دخول.php" method="POST">
          <input type="text" placeholder="اسم المستخدم" class="text" name="full_name" required><br>
          <input type="password" placeholder="كلمة المرور" class="password" name="password" required><br>
          <center>
              <button type="submit" class="btn-login" id="do-login">دخول</button>
          </center>
      </form>
  </div>
</section>
</body>
</html>