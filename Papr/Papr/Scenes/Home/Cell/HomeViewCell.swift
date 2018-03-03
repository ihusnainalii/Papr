//
//  HomeViewCell.swift
//  Papr
//
//  Created by Joan Disho on 07.01.18.
//  Copyright © 2018 Joan Disho. All rights reserved.
//

import UIKit
import RxSwift
import Nuke

class HomeViewCell: UITableViewCell, BindableType {

    // MARK: ViewModel

    var viewModel: HomeViewCellModelType!

    // MARK: IBOutlets

    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var fullNameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var photoImageView: UIImageView!
    @IBOutlet var photoButton: UIButton!
    @IBOutlet var photoHeightConstraint: NSLayoutConstraint!
    @IBOutlet var postedTimeLabel: UILabel!
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var likesNumberLabel: UILabel!
    @IBOutlet var collectPhotoButton: UIButton!
    @IBOutlet var descriptionLabel: UILabel!
    
    // MARK: Private
    private static let nukeManager = Nuke.Manager.shared
    private var disposeBag = DisposeBag()

    // MARK: Overrides

    override func awakeFromNib() {
        super.awakeFromNib()
        userImageView.rounded()
    }

    override func prepareForReuse() {
        userImageView.image = nil
        photoImageView.image = nil
        likeButton.rx.action = nil
        disposeBag = DisposeBag()
    }

    // MARK: BindableType

    func bindViewModel() {
        let inputs = viewModel.inputs
        let outputs = viewModel.outputs

        outputs.likedByUser
            .subscribe { [unowned self] likedByUser in
                guard let likedByUser = likedByUser.element else { return }
                if likedByUser {
                    self.likeButton.rx
                        .bind(to: inputs.unlikePhotoAction, input: ())
                } else {
                    self.likeButton.rx
                        .bind(to: inputs.likePhotoAction, input: ())
                }
            }
            .disposed(by: disposeBag)

        Observable
            .merge(inputs.likePhotoAction.errors, 
                   inputs.unlikePhotoAction.errors)
            .map { error in
                switch error {
                case let .underlyingError(error):
                    return error.localizedDescription
                case .notEnabled:
                    return error.localizedDescription
                }
            }
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .bind(to: inputs.alertAction.inputs)
            .disposed(by: rx.disposeBag)

        photoButton.rx.action = inputs.photoDetailsAction

        outputs.userProfileImage
            .flatMap { HomeViewCell.nukeManager.loadImage(with: $0).orEmpty }
            .bind(to: userImageView.rx.image)
            .disposed(by: disposeBag)

        Observable.concat(outputs.smallPhoto, outputs.regularPhoto)
            .flatMap { HomeViewCell.nukeManager.loadImage(with: $0).orEmpty }
            .bind(to: photoImageView.rx.image)
            .disposed(by: disposeBag)

        outputs.fullname
            .bind(to: fullNameLabel.rx.text)
            .disposed(by: disposeBag)
        
        outputs.username
            .bind(to: usernameLabel.rx.text)
            .disposed(by: disposeBag)

        outputs.photoSizeCoef
            .map { CGFloat($0) }
            .bind(to: photoHeightConstraint.rx.constant)
            .disposed(by: disposeBag)

        outputs.updated
            .bind(to: postedTimeLabel.rx.text)
            .disposed(by: disposeBag)
        
        outputs.likesNumber
            .bind(to: likesNumberLabel.rx.text)
            .disposed(by: disposeBag)
        
        outputs.likedByUser
            .map { $0 ? #imageLiteral(resourceName: "favorite") : #imageLiteral(resourceName: "unfavorite") }
            .bind(to: likeButton.rx.image())
            .disposed(by: disposeBag)
        
        outputs.photoDescription
            .bind(to: descriptionLabel.rx.text)
            .disposed(by: disposeBag)
    }
}
