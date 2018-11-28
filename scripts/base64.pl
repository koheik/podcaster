#!/usr/bin/perl


use MIME::Base64;


$str = <STDIN>;
$estr = encode_base64($str);
print $estr;
