<?php

require __DIR__ . '/vendor/autoload.php'; // Ensure this points to your Composer autoload file

use Kreait\Firebase\Factory;

try {
    // Initialize Firebase with your service account JSON file
    $factory = (new Factory)
        ->withServiceAccount('C:/wamp64/www/serviceAccountKey.json') // Replace with the path to your JSON file
        ->withDatabaseUri('https://your-project-id.firebaseio.com'); // Replace with your Firestore database URL

    // Create Firestore client
    $firestore = $factory->createFirestore();

    // Reference a Firestore collection
    $collection = $firestore->database()->collection('test_collection');

    // Add a new document
    $document = $collection->add([
        'name' => 'John Doe',
        'email' => 'john.doe@example.com',
        'created_at' => date('Y-m-d H:i:s')
    ]);

    // Print the document ID of the new entry
    echo 'Document added with ID: ' . $document->id() . PHP_EOL;

    // Fetch all documents from the collection
    $documents = $collection->documents();
    foreach ($documents as $doc) {
        if ($doc->exists()) {
            echo 'Document ID: ' . $doc->id() . PHP_EOL;
            print_r($doc->data());
        }
    }
} catch (Exception $e) {
    // Handle exceptions and errors
    echo 'Error: ' . $e->getMessage();
}
