//
//  MockerTests.swift
//  MockerTests
//
//  Created by Antoine van der Lee on 11/08/2017.
//  Copyright © 2017 WeTransfer. All rights reserved.
//

import XCTest
@testable import Mocker

final class MockerTests: XCTestCase {
    
    /// It should returned the register mocked image data as response.
    func testImageURLDataRequest() {
        let expectation = self.expectation(description: "Data request should succeed")
        let originalURL = URL(string: "https://avatars3.githubusercontent.com/u/26250426?v=4&s=400")!
        
        let mock = Mock(url: originalURL, contentType: .imagePNG, statusCode: 200, data: [
            .head: MockedData.botAvatarImageResponseHead,
            .get: MockedData.botAvatarImageFileUrl.data
        ])
        
        mock.register()
        URLSession.shared.dataTask(with: originalURL) { (data, response, error) in
            XCTAssert(error == nil)
            let image: UIImage = UIImage(data: data!)!
            let sampleImage: UIImage = UIImage(contentsOfFile: MockedData.botAvatarImageFileUrl.path)!
            
            XCTAssert(image.size == sampleImage.size, "Image should be returned mocked")
            expectation.fulfill()
        }.resume()
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    /// It should returned the register mocked image data as response for register file types.
    func testImageExtensionDataRequest() {
        let expectation = self.expectation(description: "Data request should succeed")
        let originalURL = URL(string: "https://www.wetransfer.com/sample-image.png")
        
        Mock(fileExtensions: "png", contentType: .imagePNG, statusCode: 200, data: [
            .head: MockedData.botAvatarImageResponseHead,
            .get: MockedData.botAvatarImageFileUrl.data
        ]).register()
        
        URLSession.shared.dataTask(with: originalURL!) { (data, response, error) in
            XCTAssert(error == nil)
            let image: UIImage = UIImage(data: data!)!
            let sampleImage: UIImage = UIImage(contentsOfFile: MockedData.botAvatarImageFileUrl.path)!
            
            XCTAssert(image.size == sampleImage.size, "Image should be returned mocked")
            expectation.fulfill()
        }.resume()
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    /// It should return the mocked JSON.
    func testJSONRequest() {
        struct Framework {
            let name: String?
            let owner: String?
            
            init(jsonDictionary: [String: Any]) {
                name = jsonDictionary["name"] as? String
                owner = jsonDictionary["owner"] as? String
            }
        }
        
        let expectation = self.expectation(description: "Data request should succeed")
        let originalURL = URL(string: "https://www.wetransfer.com/example.json")!
        
        Mock(url: originalURL, contentType: .json, statusCode: 200, data: [
            .get : MockedData.exampleJSON.data
            ]
        ).register()
        
        URLSession.shared.dataTask(with: originalURL) { (data, response, error) in

            guard let data = data, let jsonDictionary = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] else {
                XCTFail("Wrong data response")
                expectation.fulfill()
                return
            }
            
            let framework = Framework(jsonDictionary: jsonDictionary)
            XCTAssert(framework.name == "Mocker")
            XCTAssert(framework.owner == "WeTransfer")
            
            expectation.fulfill()
        }.resume()
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    /// It should return the additional headers.
    func testAdditionalHeaders() {
        let expectation = self.expectation(description: "Data request should succeed")
        let headers = ["testkey": "testvalue"]
        let mock = Mock(contentType: .json, statusCode: 200, data: [.get : Data()], additionalHeaders: headers)
        mock.register()
        
        URLSession.shared.dataTask(with: mock.url) { (data, response, error) in
            XCTAssert(error == nil)
            XCTAssert(((response as! HTTPURLResponse).allHeaderFields["testkey"] as! String) == "testvalue", "Additional headers should be added.")
            expectation.fulfill()
        }.resume()
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    /// It should override existing mocks.
    func testMockOverriding() {
        let expectation = self.expectation(description: "Data request should succeed")
        let mock = Mock(contentType: .json, statusCode: 200, data: [.get : Data()], additionalHeaders: ["testkey": "testvalue"])
        mock.register()
        
        let newMock = Mock(contentType: .json, statusCode: 200, data: [.get : Data()], additionalHeaders: ["newkey": "newvalue"])
        newMock.register()
        
        URLSession.shared.dataTask(with: mock.url) { (data, response, error) in
            XCTAssert(error == nil)
            XCTAssert(((response as! HTTPURLResponse).allHeaderFields["newkey"] as! String) == "newvalue", "Additional headers should be added.")
            expectation.fulfill()
        }.resume()
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    /// It should work with a custom URLSession.
    func testCustomURLSession() {
        let expectation = self.expectation(description: "Data request should succeed")
        let originalURL = URL(string: "https://www.wetransfer.com/sample-image.png")
        
        Mock(fileExtensions: "png", contentType: .imagePNG, statusCode: 200, data: [
            .head: MockedData.botAvatarImageResponseHead,
            .get: MockedData.botAvatarImageFileUrl.data
        ]).register()
        
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let urlSession = URLSession(configuration: configuration)
        
        urlSession.dataTask(with: originalURL!) { (data, response, error) in
            XCTAssert(error == nil)
            let image: UIImage = UIImage(data: data!)!
            let sampleImage: UIImage = UIImage(contentsOfFile: MockedData.botAvatarImageFileUrl.path)!
            
            XCTAssert(image.size == sampleImage.size, "Image should be returned mocked")
            expectation.fulfill()
            }.resume()
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
}
