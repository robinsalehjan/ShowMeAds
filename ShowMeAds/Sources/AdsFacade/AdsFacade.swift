//
//  AdsFacade.swift
//  ShowMeAds
//
//  Created by Robin Saleh-Jan on 19/3/2018.
//  Copyright © 2018 Robin Saleh-Jan. All rights reserved.
//

import Foundation
import UIKit

/** Abstraction that provides a simple interface to use and interact with the AdService and AdPersistenceService
 */
class AdsFacade {
    
    // MARK: - Properties
    fileprivate var adRemoteService = AdRemoteService()
    fileprivate var adPersistenceService = AdPersistenceService()
    
    static let shared = AdsFacade()
    private init() {}
    
    // MARK: - Public
    
    /** Fetch ads from the remote API
     */
    public func fetchAds(completionHandler: @escaping ((Result<[AdItem], Error>) -> Void)) {
        adRemoteService.fetchRemote(completionHandler: { [unowned self] (response) in
            switch response {
            case .success(let ads):
                let alreadyFavorited: [AdItem] = ads.map {
                    if let exists = self.adPersistenceService.exists(ad: $0) { return exists } else { return $0 }
                }
                completionHandler(Result.success(alreadyFavorited))
            case .error(let error):
                completionHandler(Result.error(error))
            }
        })
    }
    
    /** Fetch ads from Core Data
     */
    public func fetchFavoriteAds(completionHandler: @escaping ((_ ads: [AdItem]) -> Void)) {
        adPersistenceService.fetchFavoriteAds(completionHandler: { (ads) in
            completionHandler(ads)
        })
    }
    
    /** Insert an ad into Core Data
     Saves the Ad image data to disk
    */
    public func insert(ad: AdItem) {
        guard !ad.imageUrl.isEmpty && !ad.location.isEmpty && !ad.title.isEmpty else { return }
        
        let key = ad.imageUrl
        CacheFacade.shared.fetch(cacheType: .image, key: key) { (data: NSData) in
            CacheFacade.shared.saveToDisk(key: key, data: data)
        }
        
        adPersistenceService.insert(ad: ad)
    }
    
    /** Delete an ad from Core Data
     Removes any related data from the disk cache
     */
    public func delete(ad: AdItem) {
        let key = ad.imageUrl
        CacheFacade.shared.deleteFromDisk(key: key)
        
        adPersistenceService.delete(ad: ad)
    }
}
