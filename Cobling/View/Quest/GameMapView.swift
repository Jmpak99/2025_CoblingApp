//
//  GameMapView.swift
//  Cobling
//
//  Created by 박종민 on 2025/07/02.
//

import SwiftUI

struct GameMapView: View {
    @ObservedObject var viewModel: QuestViewModel
    var questTitle: String
    let subQuestId: String // 서브퀘스트 변경 감지용

    // MARK: - Tutorial Highlight Frames
    @Binding var storyButtonFrame: CGRect
    @Binding var playButtonFrame: CGRect
    @Binding var stopButtonFrame: CGRect
    @Binding var flagFrame: CGRect

    @EnvironmentObject var tabBarViewModel: TabBarViewModel
    @EnvironmentObject var authVM: AuthViewModel

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var isHintOn = false
    @State private var isStoryOn = false

    // 타입 체크 부담을 줄이기 위해 타일 크기를 프로퍼티로 분리
    private let tileSize: CGFloat = 36

    // mapData 접근을 분리해서 body 내부 복잡도 감소
    private var map: [[Int]] {
        viewModel.mapData
    }

    // DB stage → 에셋 prefix (게임 캐릭터용)
    private var gameCharacterAssetPrefix: String {
        let stage = (authVM.userProfile?.character.stage ?? "egg")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let allowed: Set<String> = ["egg", "kid", "cobling", "legend"]
        let safeStage = allowed.contains(stage) ? stage : "egg"

        return "cobling_stage_\(safeStage)"
    }

    // 방향 → suffix 매핑
    // up    -> back
    // down  -> front
    // left  -> left
    // right -> right
    private var directionSuffix: String {
        switch viewModel.characterDirection {
        case .up: return "back"
        case .down: return "front"
        case .left: return "left"
        case .right: return "right"
        }
    }

    // 최종 캐릭터 에셋 이름
    // ex) "cobling_stage_kid_front"
    private var gameCharacterDirectionalAssetName: String {
        "\(gameCharacterAssetPrefix)_\(directionSuffix)"
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            backgroundView

            mainContentView

            storyOverlayView

            hintOverlayView
        }
        .onAppear {
            refreshTutorialFrames()
        }
        .onChange(of: viewModel.characterPosition.row) { _ in
            refreshTutorialFrames()
        }
        .onChange(of: viewModel.characterPosition.col) { _ in
            refreshTutorialFrames()
        }
        .onChange(of: viewModel.characterDirection) { _ in
            refreshTutorialFrames()
        }
        .onChange(of: subQuestId) { _ in
            isStoryOn = false
            isHintOn = false
        }
    }

    // MARK: - Background

    // 배경 뷰 분리
    private var backgroundView: some View {
        Color(hex: "#FFF2DC")
            .ignoresSafeArea()
    }

    // MARK: - Main Content

    // 메인 전체 레이아웃 분리
    private var mainContentView: some View {
        VStack(spacing: 4) {
            Spacer().frame(height: 42)

            titleView

            topButtonBarView

            mapContainerView
        }
    }

    // 타이틀 뷰 분리
    private var titleView: some View {
        HStack {
            Spacer()
            Text(questTitle)
                .font(.gmarketBold34)
                .foregroundColor(Color(hex: "#3A3A3A"))
                .padding(.top, 12)
            Spacer()
        }
        .padding(.top, 16)
    }

    // 상단 버튼 바 분리
    private var topButtonBarView: some View {
        HStack {
            HStack(spacing: 12) {
                playButtonView
                stopButtonView

//                Button {
//                    withAnimation {
//                        isHintOn.toggle()
//                    }
//                } label: {
//                    Image(isHintOn ? "gp_hint_on" : "gp_hint_off")
//                        .resizable()
//                        .frame(width: 28, height: 28)
//                }
            }
            .padding(.leading, 40)

            Spacer()

            Button {
                appState.isInGame = false
                dismiss()
            } label: {
                Image("gp_out")
                    .resizable()
                    .frame(width: 32, height: 32)
            }
            .padding(.trailing, 40)
            .padding(.top, 10)
        }
    }

    // 플레이 버튼 분리
    private var playButtonView: some View {
        Button {
            viewModel.startExecution()
        } label: {
            Image(systemName: "play.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(hex: "#58ED98"))
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        playButtonFrame = geo.frame(in: .global)
                    }
                    .onChange(of: viewModel.isExecuting) { _ in
                        playButtonFrame = geo.frame(in: .global)
                    }
            }
        )
    }

    // 정지 버튼 분리
    private var stopButtonView: some View {
        Button {
            viewModel.stopExecution()
        } label: {
            Image(systemName: "stop.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(hex: "#E85A5A"))
                .frame(width: 28, height: 28)
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        stopButtonFrame = geo.frame(in: .global)
                    }
                    .onChange(of: viewModel.isExecuting) { _ in
                        stopButtonFrame = geo.frame(in: .global)
                    }
            }
        )
    }

    // MARK: - Map

    // 맵 전체 컨테이너 분리
    private var mapContainerView: some View {
        ZStack {
            mapTilesView
            characterLayerView
        }
        .padding(.top, 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    // 맵 타일 전체 뷰 분리
    private var mapTilesView: some View {
        VStack(spacing: 0) {
            ForEach(map.indices, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(map[row].indices, id: \.self) { col in
                        mapCellView(row: row, col: col)
                    }
                }
            }
        }
    }

    // 셀 단위 렌더링 분리
    @ViewBuilder
    private func mapCellView(row: Int, col: Int) -> some View {
        ZStack {
            tileImageView(row: row, col: col)
            enemyImageView(row: row, col: col)
            flagImageView(row: row, col: col)
        }
        .frame(width: tileSize, height: tileSize)
    }

    // 타일 이미지 분리
    @ViewBuilder
    private func tileImageView(row: Int, col: Int) -> some View {
        if isWalkableTile(row: row, col: col) {
            Image("iv_game_way_1")
                .resizable()
                .scaledToFit()
                .frame(width: tileSize, height: tileSize)
        }
    }

    // 적 이미지 분리
    @ViewBuilder
    private func enemyImageView(row: Int, col: Int) -> some View {
        if hasEnemy(row: row, col: col) {
            Image("cobling_character_enemies")
                .resizable()
                .scaledToFit()
                .frame(
                    width: tileSize * 1.4,
                    height: tileSize * 1.4
                )
                .offset(y: -8)
        }
    }

    // 깃발 이미지 분리
    @ViewBuilder
    private func flagImageView(row: Int, col: Int) -> some View {
        if isGoalPosition(row: row, col: col) {
            Image("gp_flag")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .offset(y: -15)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                flagFrame = geo.frame(in: .global)
                            }
                            .onChange(of: viewModel.characterPosition.row) { _ in
                                flagFrame = geo.frame(in: .global)
                            }
                            .onChange(of: viewModel.characterPosition.col) { _ in
                                flagFrame = geo.frame(in: .global)
                            }
                    }
                )
        }
    }

    // 캐릭터 레이어 분리
    private var characterLayerView: some View {
        GeometryReader { _ in
            let x = CGFloat(viewModel.characterPosition.col) * tileSize + tileSize / 2
            let y = CGFloat(viewModel.characterPosition.row) * tileSize + tileSize / 2

            Image(gameCharacterDirectionalAssetName)
                .resizable()
                .scaledToFit()
                .frame(
                    width: tileSize * 1.4,
                    height: tileSize * 1.4
                )
                .position(x: x, y: y - 15)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.12), value: viewModel.characterDirection)
        }
        .frame(
            width: CGFloat(map.first?.count ?? 0) * tileSize,
            height: CGFloat(map.count) * tileSize
        )
    }

    // MARK: - Story Overlay

    // 스토리 오버레이 분리
    private var storyOverlayView: some View {
        VStack {
            Spacer()
            HStack(alignment: .bottom, spacing: 8) {
                Spacer()

                ZStack(alignment: .trailing) {
                    if isStoryOn,
                       let message = viewModel.storyMessage {
                        SpeechBubbleView(message: message)
                            .transition(.opacity)
                            .padding(.trailing, 50)
                    }

                    Button {
                        withAnimation {
                            isStoryOn.toggle()
                        }
                    } label: {
                        Image(isStoryOn ? "gp_story_btn_on" : "gp_story_btn_off")
                            .resizable()
                            .frame(width: 40, height: 40)
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    storyButtonFrame = geo.frame(in: .global)
                                }
                                .onChange(of: isStoryOn) { _ in
                                    storyButtonFrame = geo.frame(in: .global)
                                }
                        }
                    )
                }
                .padding(.trailing, 30)
            }
            .padding(.bottom, 12)
        }
    }

    // MARK: - Hint Overlay

    // 힌트 오버레이 분리
    @ViewBuilder
    private var hintOverlayView: some View {
        if isHintOn,
           let message = viewModel.hintMessage {
            VStack {
                Spacer().frame(height: 160)
                HStack {
                    Spacer().frame(width: 80)
                    SpeechBubbleView(message: message)
                        .fixedSize()
                        .padding(.top, 8)
                        .transition(.opacity)
                    Spacer()
                }
                Spacer()
            }
        }
    }

    // MARK: - Helper

    // 길 타일 판별 함수 분리
    private func isWalkableTile(row: Int, col: Int) -> Bool {
        guard row < map.count, col < map[row].count else { return false }
        let value = map[row][col]
        return value == 1 || value == 2
    }

    // 적 존재 여부 판별 함수 분리
    private func hasEnemy(row: Int, col: Int) -> Bool {
        viewModel.enemies.contains { enemy in
            enemy.row == row && enemy.col == col
        }
    }

    // 목표 위치 판별 함수 분리
    private func isGoalPosition(row: Int, col: Int) -> Bool {
        viewModel.goalPosition.row == row && viewModel.goalPosition.col == col
    }

    // MARK: - Tutorial Frame Refresh
    private func refreshTutorialFrames() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            // 각 GeometryReader의 onAppear / onChange에서 개별 반영되므로
            // 여기서는 레이아웃 갱신 타이밍을 한 번 더 보정하는 용도입니다.
        }
    }
}
