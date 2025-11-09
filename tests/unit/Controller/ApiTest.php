<?php

declare(strict_types=1);

namespace Controller;

use OCA\NextcloudAppTemplate\AppInfo\Application;
use OCA\NextcloudAppTemplate\Controller\ApiController;
use OCP\IAppConfig;
use OCP\IL10N;
use OCP\IRequest;
use PHPUnit\Framework\TestCase;

class ApiTest extends TestCase {
	public function testGetHello(): void {
		$request = $this->createMock(IRequest::class);
		$config = $this->createMock(IAppConfig::class);
		$l10n = $this->createMock(IL10N::class);

		// Mock config to return empty string (no previous hello)
		$config->method('getValueString')
			->willReturn('');

		// Mock translation to return a simple string
		$l10n->method('t')
			->willReturnCallback(function ($text, $params = []) {
				return $text;
			});

		$controller = new ApiController(Application::APP_ID, $request, $config, $l10n);

		$resp = $controller->getHello()->getData();

		$this->assertIsArray($resp);
		$this->assertArrayHasKey('message', $resp);
		$this->assertArrayHasKey('at', $resp);
		$this->assertEquals('👋 Hello from server!', $resp['message']);
		$this->assertNull($resp['at']);
	}

	public function testPostHello(): void {
		$request = $this->createMock(IRequest::class);
		$config = $this->createMock(IAppConfig::class);
		$l10n = $this->createMock(IL10N::class);

		// Mock translation to return formatted string
		$l10n->method('t')
			->willReturnCallback(function ($text, $params = []) {
				if (empty($params)) {
					return $text;
				}
				return vsprintf(str_replace('%s', '%s', $text), $params);
			});

		// Expect setValueString to be called to save the timestamp
		$config->expects($this->once())
			->method('setValueString');

		$controller = new ApiController(Application::APP_ID, $request, $config, $l10n);

		$resp = $controller->postHello([
			'name' => 'World',
			'theme' => 'dark',
			'items' => ['item1', 'item2'],
			'counter' => 5
		])->getData();

		$this->assertIsArray($resp);
		$this->assertArrayHasKey('message', $resp);
		$this->assertArrayHasKey('at', $resp);
		$this->assertStringContainsString('World', $resp['message']);
		$this->assertNotEmpty($resp['at']);
	}
}
