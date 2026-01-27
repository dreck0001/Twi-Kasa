import SwiftUI

struct LaunchScreenView: View {
    @State private var showKasa = false
    @State private var kasaOffset: CGFloat = -60
    @State private var kasaOpacity: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("porcupine")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color.black.opacity(0.4), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geometry.size.height * 0.15)
                    
                    Spacer()
                    
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geometry.size.height * 0.3)
                }
                
                VStack(spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("Twi")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(" Kasa")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: kasaOffset)
                            .opacity(kasaOpacity)
                    }
                    
                    HStack(spacing: 6) {
                        Text("/ʧwi kasa/")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(8)
                    .opacity(kasaOpacity)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                showKasa = true
                kasaOffset = 0
                kasaOpacity = 1
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
