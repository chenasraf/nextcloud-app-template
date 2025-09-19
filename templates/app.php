<?php

use OCA\NextcloudAppTemplate\AppInfo\Application;
use OCP\Util;

/* @var array $_ */
$script = $_['script'];
Util::addScript(Application::APP_ID, Application::JS_DIR . "/nextcloud-app-template-$script");
Util::addStyle(Application::APP_ID, Application::CSS_DIR . '/nextcloud-app-template-style');
?>
<div id="nextcloud-app-template-app"></div>
