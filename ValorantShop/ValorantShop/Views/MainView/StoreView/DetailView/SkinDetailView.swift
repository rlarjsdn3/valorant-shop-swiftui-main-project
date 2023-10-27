//
//  SkinDetailView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/26.
//

import SwiftUI
import VideoPlayer

struct SkinDetailView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @State private var selectedLevel: Int = 0
    @State private var selectedChroma: Int = 0
    
    @State private var streammedVideoUrl: URL?
    @State var play: Bool = false
    
    @Environment(\.dismiss) var dismiss
    
    // MARK: - PROPERTIES
    
    var skinInfo: SkinInfo
    
    // MARK: - INITALIZER
    
    init(_ skinInfo: SkinInfo) {
        self.skinInfo = skinInfo
    }
    
    // MARK: - BODY
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 18) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title)
                        .foregroundColor(Color.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 13)
            .padding(.bottom, 18)
            .padding(.horizontal)
            .overlay {
                Text("스킨 세부 정보")
                    .font(.system(.title2, weight: .semibold))
            }
            .overlay(alignment: .bottom) {
                Divider()
            }
            .background(
                Color.systemBackground
                    .ignoresSafeArea()
            )
            
            ScrollView {
                
                // - 기본 이미지
                VStack(alignment: .leading) {
                    Text("기본 정보")
                        .font(.system(.title3, weight: .semibold))
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        if let uuid = skinInfo.skin.chromas.first?.uuid {
                            kingFisherImage(of: ImageType.weaponSkins, uuid: uuid)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .padding()
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("\(skinInfo.skin.displayName)")
                            
                            Spacer()
                            
                            Image("VP")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 25, height: 25)
                            Text("\(skinInfo.price.basePrice)")
                        }
                        .fontWeight(.semibold)
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        
                    }
                    .background(Color.systemBackground)
                    
                    if skinInfo.skin.levels.count != 1 {
                        HStack {
                            Text("레벨")
                                .font(.system(.title3, weight: .semibold))
                            
                            Button {
                                play.toggle()
                            } label: {
                                Group {
                                    if play {
                                        Image(systemName: "pause.fill")
                                    } else {
                                        Image(systemName: "play.fill")
                                    }
                                }
                                .font(.title3)
                                .foregroundColor(Color.primary)
                            }
                            
                            
                            Spacer()
                            
                            // ❗️ 미완성 코드
                            Text("\(skinInfo.skin.levels[selectedLevel].levelItem?.displayName ?? "")")
                                .font(.system(.title3))
                        }
                        .padding([.horizontal, .top])
                        
                        VStack(spacing: 0) {
                            if let url = streammedVideoUrl {
                                VideoPlayer(url: url, play: $play)
                                    .autoReplay(true)
                                    .aspectRatio(16/9, contentMode: .fill)
                                    .cornerRadius(10)
                                    .padding([.horizontal, .top])
                                    .padding(.bottom, 5)
                            }
                            
                            HStack {
                                Picker("Level Picker", selection: $selectedLevel) {
                                    ForEach(skinInfo.skin.levels.indices, id: \.self) { index in
                                        Text("\(index+1)레벨")
                                            .tag(index)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            .fontWeight(.semibold)
                            .padding(.vertical, 10)
                            .padding(.horizontal)
                            
                        }
                        .background(Color.systemBackground)
                    }
                    
                    if skinInfo.skin.chromas.count != 1 {
                            HStack {
                                Text("변형")
                                    .font(.system(.title3, weight: .semibold))
                                
                                Spacer()
                                
                                // ❗️ 미완성 코드
                                Text("-")
                                    .font(.system(.title3))
                            }
                            .padding([.horizontal, .top])
                            
                            VStack(spacing: 0) {
                                kingFisherImage(of: ImageType.weaponSkins, uuid: skinInfo.skin.chromas[selectedChroma].uuid)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 150)
                                    .padding()
                                
                                HStack {
                                    Picker("Chroma Picker", selection: $selectedChroma) {
                                        ForEach(skinInfo.skin.chromas.indices, id: \.self) { index in
                                            Text("\(index+1)레벨")
                                                .tag(index)
                                                .onAppear {
                                                    print("\(skinInfo.skin.chromas[index].displayName)")
                                                }
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }
                                .fontWeight(.semibold)
                                .padding(.vertical, 10)
                                .padding(.horizontal)
                            }
                            .background(Color.systemBackground)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.secondarySystemBackground)
            .scrollIndicators(.never)
        }
        .onAppear {
            // 스킨 세부 정보가 보이면
            // 첫 번째 레벨의 스트리밍 비디오를 불러오기
            guard let url = URL(string: skinInfo.skin.levels.first?.streamedVideo ?? "") else {
                return
            }
            // 화면에 출력하기
            streammedVideoUrl = url
        }
        .onChange(of: selectedLevel) { newValue in
            // 클릭한 레벨이 바뀌면
            // 해당하는 레벨의 스트리밍 비디오를 불러오기
            guard let url = URL(string: skinInfo.skin.levels[newValue].streamedVideo ?? "") else {
                return
            }
            // 화면에 출력하기
            streammedVideoUrl = url
        }
    }
}

// MARK: - PREVIEW

struct SkinDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SkinDetailView(PreviewsData.skinInfo)
    }
}
