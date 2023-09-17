//
//  View+Extension.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/17.
//

import UIKit
import SwiftUI

extension View {
    
    // For Load Image Data
    func loadImage(of type: ImageType, uuid: String) -> Image {
        // 경로 접근을 위한 파일 매니저 선언하기
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        // 경로 설정하기
        let imageUrl = documents.appending(path: makeImageFileName(of: type, uuid: uuid))
        // 해당 경로의 이미지 데이터 가져오기
        guard let imageData = try? Data(contentsOf: imageUrl) else { return Image("") }
        // 이미지 데이터로 UIImage 만들기
        guard let uiImage = UIImage(data: imageData) else { return Image("") }
        // UIImage로 Image 만들기
        let image = Image(uiImage: uiImage)
        
        // 결과 반환하기
        return image
    }
    
    private func makeImageFileName(of type: ImageType, uuid: String) -> String {
        return "\(type.prefixFileName)-\(uuid).png"
    }
}
