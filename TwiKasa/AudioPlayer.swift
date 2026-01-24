import AVFoundation

class AudioPlayer: NSObject, ObservableObject {
    @Published var isPlaying = false
    private var player: AVAudioPlayer?
    
    override init() {
        super.init()
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    func play(filenames: [String]) {
        for filename in filenames {
            let components = filename.split(separator: ".")
            guard components.count == 2 else { continue }
            
            let nameWithoutExt = String(components[0])
            let ext = String(components[1])
            
            guard let url = Bundle.main.url(forResource: nameWithoutExt, withExtension: ext) else {
                continue
            }
            
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.delegate = self
                player?.play()
                isPlaying = true
                return
            } catch {
                continue
            }
        }
    }
    
    func stop() {
        player?.stop()
        isPlaying = false
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
}
