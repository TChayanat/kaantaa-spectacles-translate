import {HandInputData} from "../../Providers/HandInputData/HandInputData"
import {HandType} from "../../Providers/HandInputData/HandType"
import BaseInteractor from "./BaseInteractor"
import {
  ColliderTargetProvider,
  ColliderTargetProviderConfig,
} from "./ColliderTargetProvider"
import {TargetingMode} from "./Interactor"

export type DirectTargetProviderConfig = ColliderTargetProviderConfig & {
  handType: HandType
  debugEnabled: boolean
  colliderEnterRadius: number
  colliderExitRadius: number
}

/**
 * Hand based direct target provider. Uses a collider positioned
 * at the center position of the index and thumb
 */
export class DirectTargetProvider extends ColliderTargetProvider {
  readonly targetingMode: TargetingMode = TargetingMode.Direct

  private handProvider: HandInputData = HandInputData.getInstance()

  private hand = this.handProvider.getHand(this.config.handType)

  private overlapEvent: OverlapStayEventArgs | null = null

  private colliders: ColliderComponent[]

  private _drawDebug = this.config.debugEnabled

  constructor(
    interactor: BaseInteractor,
<<<<<<< HEAD
    protected config: DirectTargetProviderConfig,
=======
    protected override config: DirectTargetProviderConfig
>>>>>>> crop
  ) {
    super(interactor, config)

    this.colliders = []

    this.colliders.push(
      this.createCollider(
        this.ownerSceneObject,
        config.colliderEnterRadius,
        this.onColliderOverlapStay.bind(this),
        null,
<<<<<<< HEAD
        config.debugEnabled,
      ),
=======
        config.debugEnabled
      )
>>>>>>> crop
    )

    this.colliders.push(
      this.createCollider(
        this.ownerSceneObject,
        config.colliderExitRadius,
        null,
        this.onColliderOverlapExit.bind(this),
<<<<<<< HEAD
        config.debugEnabled,
      ),
=======
        config.debugEnabled
      )
>>>>>>> crop
    )

    this.ownerSceneObject.enabled = false
    this.hand.onHandFound.add(() => {
      this.ownerSceneObject.enabled = true
    })
    this.hand.onHandLost.add(() => {
      this.ownerSceneObject.enabled = false
    })
  }

  set drawDebug(debug: boolean) {
    this._drawDebug = debug

    for (const collider of this.colliders) {
      collider.debugDrawEnabled = debug
    }
  }

  get drawDebug(): boolean {
    return this._drawDebug
  }

  /** @inheritdoc */
  protected isAvailable(): boolean {
    return (
      this.hand.indexTip !== null &&
      this.hand.thumbTip !== null &&
      this.hand.enabled &&
      (this.hand.isTracked() || this.hand.isPinching())
    )
  }

  /** @inheritdoc */
  override update(): void {
    if (this.isAvailable()) {
      const newPosition = this.getNextPosition()
      this.ownerSceneObject.getTransform().setWorldPosition(newPosition)
      this.ownerSceneObject.enabled = true

      if (!this.config.shouldPreventTargetUpdate?.()) {
        if (this.overlapEvent === null) {
          this.clearCurrentInteractableHitInfo()
        }
        this.overlapEvent = null
      }
    } else {
      this.ownerSceneObject.enabled = false
      this.clearCurrentInteractableHitInfo()
<<<<<<< HEAD
      this._currentInteractionPlanes = []
=======
>>>>>>> crop
    }
  }

  protected override onColliderOverlapStay(
    event: OverlapEnterEventArgs,
<<<<<<< HEAD
    allowOutOfFovInteraction = false,
=======
    allowOutOfFovInteraction = true
>>>>>>> crop
  ): void {
    this.overlapEvent = event
    super.onColliderOverlapStay(event, allowOutOfFovInteraction)
  }

  protected override onColliderOverlapExit(event: OverlapEnterEventArgs): void {
    if (this.config.shouldPreventTargetUpdate?.()) {
      return
    }

<<<<<<< HEAD
    super.onColliderOverlapExit(event)
=======
    if (
      event.overlap.collider === this._currentInteractableHitInfo?.hit.collider
    ) {
      this._currentInteractableHitInfo = null
    }
>>>>>>> crop
  }

  /** @inheritdoc */
  protected getNextPosition(): vec3 {
    const indexTip = this.hand.indexTip?.position
    const thumbTip = this.hand.thumbTip?.position

    if (indexTip === undefined || thumbTip === undefined) {
      return vec3.zero()
    }

    return indexTip.add(thumbTip).uniformScale(0.5)
  }
}
