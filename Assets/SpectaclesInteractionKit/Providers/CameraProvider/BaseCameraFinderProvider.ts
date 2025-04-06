import {bfs} from "../../Utils/algorithms"
import BaseWorldCameraProvider from "./BaseWorldCameraProvider"

/**
 * Extends {@link BaseWorldCameraProvider} by providing functionality that
 * allows for searching for the {@link Camera} during construction.
 */
export default abstract class BaseCameraFinderProvider extends BaseWorldCameraProvider {
  /**
   * Checks the {@link SceneObject} passed if it has a {@link Camera} component
   * with the right render target.
   * Returns a reference to the {@link Camera} if true, null if not.
   */
  protected getSameRenderTargetCamera(object: SceneObject): Camera | null {
    const cameraComponent = object.getComponent("Component.Camera")

    // It is possible the liveTarget is not set, in this case we use the captureTarget
    const targetRenderTarget =
      global.scene.liveTarget !== null
        ? global.scene.liveTarget
        : global.scene.captureTarget

    if (
      object.enabled &&
      cameraComponent !== null &&
      cameraComponent.type === Camera.Type.Perspective &&
      cameraComponent.renderTarget.isSame(targetRenderTarget)
    ) {
      return cameraComponent
    } else {
      return null
    }
  }

  protected setCamera(cameraComponent: Camera): void {
    if (cameraComponent === null) {
      throw new Error(
<<<<<<< HEAD
        "Could not find any suitable camera in the scene, make sure it is setup correctly",
=======
        "Could not find any suitable camera in the scene, make sure it is setup correctly"
>>>>>>> crop
      )
    }
    if (
      this.lookForDeviceTrackingComponent(cameraComponent.getSceneObject()) ===
      null
    ) {
      throw new Error(
<<<<<<< HEAD
        "Your main camera is currently missing a 'Device Tracking Component'. Set your `Device Tracking Component` with Tracking Mode: World for spatial movement in your Lens.",
=======
        "Your main camera is currently missing a 'Device Tracking Component'. Set your `Device Tracking Component` with Tracking Mode: World for spatial movement in your Lens."
>>>>>>> crop
      )
    }
    this.cameraComponent = cameraComponent
    this.cameraTransform = this.cameraComponent.getTransform()
  }

  private lookForDeviceTrackingComponent(
<<<<<<< HEAD
    sceneObject: SceneObject,
  ): DeviceTracking | null {
    const deviceTrackingComponent = sceneObject.getComponent(
      "Component.DeviceTracking",
=======
    sceneObject: SceneObject
  ): DeviceTracking | null {
    const deviceTrackingComponent = sceneObject.getComponent(
      "Component.DeviceTracking"
>>>>>>> crop
    )

    return deviceTrackingComponent
  }

  protected bfsFromRoot(
<<<<<<< HEAD
    predicate: (sceneObject: SceneObject) => Camera | null,
=======
    predicate: (sceneObject: SceneObject) => Camera | null
>>>>>>> crop
  ): Camera | null {
    // Get root objects from the scene
    const rootObjects = []
    const objectCount = global.scene.getRootObjectsCount()
    for (let i = 0; i < objectCount; i++) {
      rootObjects.push(global.scene.getRootObject(i))
    }

    return bfs<Camera | null>(rootObjects, predicate)
  }
}
