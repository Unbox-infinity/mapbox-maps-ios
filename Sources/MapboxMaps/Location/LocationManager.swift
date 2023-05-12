import CoreLocation
import UIKit

/// An object responsible for notifying the map view about location-related events,
/// such as a change in the device’s location.
public final class LocationManager {

    /// Represents the latest location received from the location provider.
    public var latestLocation: Location? {
        return locationProducer.latestLocation
    }

    /// The object that acts as the delegate of the location manager.
    public weak var delegate: LocationPermissionsDelegate?

    /// The current underlying location provider. Use `overrideLocationProvider(with:)` to substitute a different provider.
    /// Avoid manipulating the location provider directly. LocationManager assumes full responsibility for starting and stopping location
    /// and heading updates as needed.
    public var locationProvider: LocationProvider! {
        return locationProducer.locationProvider
    }

    /// The set of objects that are currently consuming location updates.
    /// The returned object is a copy of the underlying one, so mutating it will have no effect.
    public var consumers: [LocationConsumer] {
        return locationProducer.consumers
    }

    /// Configuration options for the location manager.
    public var options = LocationOptions() {
        didSet {
            syncOptions()
        }
    }

    private let locationProducer: LocationProducerProtocol
    private let interpolatedLocationProducer: InterpolatedLocationProducerProtocol

    /// Manager that handles the visual puck element.
    /// Only created if `showsUserLocation` is `true`.
    private let puckManager: PuckManagerProtocol

    internal init(locationProducer: LocationProducerProtocol,
                  interpolatedLocationProducer: InterpolatedLocationProducerProtocol,
                  puckManager: PuckManagerProtocol) {
        self.locationProducer = locationProducer
        self.interpolatedLocationProducer = interpolatedLocationProducer
        self.puckManager = puckManager
        locationProducer.delegate = self
        syncOptions()
    }

    /// Overrides the default(CoreLocation-based) location provider with the supplied one.
    /// - Parameter customLocationProvider: The location provider to be used for location-related things.
    public func overrideLocationProvider(with customLocationProvider: LocationProvider) {
        locationProducer.locationProvider = customLocationProvider
    }

    /// The location manager holds weak references to consumers, client code should retain these references.
    public func addLocationConsumer(newConsumer consumer: LocationConsumer) {
        locationProducer.add(consumer)
    }

    /// Removes a location consumer from the location manager.
    public func removeLocationConsumer(consumer: LocationConsumer) {
        locationProducer.remove(consumer)
    }

    /// Adds ``PuckLocationConsumer`` to the location manager.
    ///
    /// An instance of ``PuckLocationConsumer`` will get the accurate (interpolated) location of the puck as it moves,
    /// as opposed to the ``LocationConsumer`` that gets updated only when the ``LocationProvider`` has emitted a new location.
    /// - Important: The location manager holds a weak reference to the consumer, thus client should retain these references.
    public func addPuckLocationConsumer(_ consumer: PuckLocationConsumer) {
        interpolatedLocationProducer.addPuckLocationConsumer(consumer)
    }

    /// Removes a ``PuckLocationConsumer`` from the location manager.
    public func removePuckLocationConsumer(_ consumer: PuckLocationConsumer) {
        interpolatedLocationProducer.removePuckLocationConsumer(consumer)
    }

    /// Allows a custom case to request full accuracy
    @available(iOS 14.0, *)
    public func requestTemporaryFullAccuracyPermissions(withPurposeKey purposeKey: String) {
        locationProvider.requestTemporaryFullAccuracyAuthorization(withPurposeKey: purposeKey)
    }

    private func syncOptions() {
        locationProducer.locationProvider.locationProviderOptions = options
        puckManager.puckType = options.puckType
        puckManager.puckBearingSource = options.puckBearingSource
        puckManager.puckBearingEnabled = options.puckBearingEnabled

        interpolatedLocationProducer.isEnabled = options.puckType != nil
    }
}

extension LocationManager: LocationProducerDelegate {
    internal func locationProducer(_ locationProducer: LocationProducerProtocol,
                                   didFailWithError error: Error) {
        delegate?.locationManager(self, didFailToLocateUserWithError: error)
    }

    internal func locationProducer(_ locationProducer: LocationProducerProtocol,
                                   didChangeAccuracyAuthorization accuracyAuthorization: CLAccuracyAuthorization) {
        delegate?.locationManager(self, didChangeAccuracyAuthorization: accuracyAuthorization)
    }

    func locationProducerShouldDisplayHeadingCalibration(_ locationProducer: LocationProducerProtocol) -> Bool {
        return delegate?.locationManagerShouldDisplayHeadingCalibration(self) ?? false
    }
}
