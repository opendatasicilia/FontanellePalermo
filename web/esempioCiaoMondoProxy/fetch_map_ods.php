<?php

header('Content-type: image/png');

$x = $_GET['x'];
$y = $_GET['y'];
$z = $_GET['z'];

$urlBegin = 'https://2.aerial.maps.api.here.com/maptile/2.1/maptile/newest/hybrid.day';
/* qui  sotto vanno inseriti app_id e app_code di here */
$urlEnd = '/256/png?app_id=XXXXX&app_code=XXXXXX';


$fullUrl = "$urlBegin/$z/$x/$y$urlEnd";


$curl = curl_init();
curl_setopt_array($curl, [
    CURLOPT_RETURNTRANSFER => 1,
    CURLOPT_URL => $fullUrl,
    CURLOPT_USERAGENT => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.108 Safari/537.36'
]);
$content = curl_exec($curl);
curl_close($curl);

echo $content

?>
