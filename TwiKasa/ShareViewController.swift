//
//  ShareViewController.swift
//  TwiKasa
//
//  Created by Throw Catchers on 1/24/26.
//

import SwiftUI
import UIKit

struct ShareViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
