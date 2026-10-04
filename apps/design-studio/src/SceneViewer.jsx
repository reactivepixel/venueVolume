import React, { useEffect, useRef, useState } from "react";
import * as THREE from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import { PointerLockControls } from "three/addons/controls/PointerLockControls.js";
import { ISOMETRIC_VIEWS, isometricCamera } from "./venue-scene";

export default function SceneViewer({
  model,
  ghost,
  hideCeiling,
  spawn,
  view,
  onReady,
  onError,
}) {
  const host = useRef(null),
    api = useRef(null);
  const [position, setPosition] = useState(null);
  useEffect(() => {
    let renderer,
      controls,
      walkControls,
      observer,
      disposed = false,
      frame,
      previousFrame = performance.now(),
      lastPositionUpdate = 0;
    const keys = new Set();
    let onClick, onKeyDown, onKeyUp, onBlur;
    const originals = new Map(),
      faded = new Map();
    try {
      renderer = new THREE.WebGLRenderer({
        antialias: true,
        preserveDrawingBuffer: true,
      });
      renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
      renderer.setClearColor(0x101925);
      renderer.domElement.setAttribute(
        "aria-label",
        "Interactive 3D venue and fixture placement",
      );
      renderer.domElement.setAttribute("role", "img");
      host.current.appendChild(renderer.domElement);
      const scene = new THREE.Scene();
      scene.add(model);
      scene.add(new THREE.HemisphereLight(0xf0f6ff, 0x66778f, 2.6));
      const light = new THREE.DirectionalLight(0xffffff, 3);
      light.position.set(5, 10, 8);
      scene.add(light);
      const fill = new THREE.DirectionalLight(0xc9e6ff, 2);
      fill.position.set(-5, -5, -8);
      scene.add(fill);
      const bounds = new THREE.Box3().setFromObject(model);
      let camera = isometricCamera(bounds, ISOMETRIC_VIEWS[0].direction);
      const draw = () => renderer.render(scene, camera);
      function setCamera(next, target) {
        walkControls?.unlock();
        walkControls?.dispose();
        walkControls = null;
        setPosition(null);
        controls?.dispose();
        camera = next;
        controls = new OrbitControls(camera, renderer.domElement);
        controls.target.copy(target);
        controls.enableDamping = false;
        controls.addEventListener("change", draw);
        controls.update();
        draw();
      }
      let fittedTarget = model;
      function walk() {
        if (!spawn) return;
        controls?.dispose();
        controls = null;
        walkControls?.unlock();
        walkControls?.dispose();
        const size = renderer.getSize(new THREE.Vector2());
        camera = new THREE.PerspectiveCamera(70, size.x / size.y, 0.05, 250);
        const eyeHeight = Math.min(
          1.65,
          (spawn.bounds.max[1] - spawn.position[1]) * 0.7,
        );
        camera.position.set(
          spawn.position[0],
          spawn.position[1] + eyeHeight,
          spawn.position[2],
        );
        camera.rotation.set(0, spawn.yaw, 0, "YXZ");
        walkControls = new PointerLockControls(camera, renderer.domElement);
        walkControls.addEventListener("change", draw);
        keys.clear();
        setPosition(camera.position.toArray());
        draw();
      }
      function fit(direction, target = model) {
        fittedTarget = target;
        const box = new THREE.Box3().setFromObject(target);
        const size = renderer.getSize(new THREE.Vector2());
        setCamera(
          isometricCamera(box, direction, size.x / size.y),
          box.getCenter(new THREE.Vector3()),
        );
      }
      const resize = () => {
        const { width, height } = host.current.getBoundingClientRect();
        renderer.setSize(width, height);
        if (camera.isPerspectiveCamera) {
          camera.aspect = width / height;
          camera.updateProjectionMatrix();
          draw();
          return;
        }
        if (controls) {
          const direction = camera.position
            .clone()
            .sub(controls.target)
            .normalize()
            .toArray();
          fit(direction, fittedTarget);
          return;
        }
        const half = camera.top;
        camera.left = (-half * width) / height;
        camera.right = (half * width) / height;
        camera.updateProjectionMatrix();
        draw();
      };
      resize();
      fit(ISOMETRIC_VIEWS[0].direction);
      observer = new ResizeObserver(resize);
      observer.observe(host.current);
      model.traverse((o) => {
        if (o.userData.kind === "venue")
          o.traverse((part) => {
            if (!part.material) return;
            originals.set(part, part.material);
            const clone = (m) => {
              const n = m.clone();
              n.transparent = true;
              n.opacity = 0.14;
              n.depthWrite = false;
              return n;
            };
            faded.set(
              part,
              Array.isArray(part.material)
                ? part.material.map(clone)
                : clone(part.material),
            );
          });
      });
      onClick = function () {
        if (walkControls && !walkControls.isLocked) walkControls.lock();
      };
      onKeyDown = function (event) {
        if (!walkControls?.isLocked) return;
        if (event.code === "Escape") {
          walkControls.unlock();
          keys.clear();
          return;
        }
        if (
          [
            "KeyW",
            "KeyA",
            "KeyS",
            "KeyD",
            "ArrowUp",
            "ArrowDown",
            "ArrowLeft",
            "ArrowRight",
          ].includes(event.code)
        ) {
          event.preventDefault();
          keys.add(event.code);
        }
      };
      onKeyUp = function (event) {
        keys.delete(event.code);
      };
      onBlur = function () {
        keys.clear();
      };
      renderer.domElement.addEventListener("click", onClick);
      window.addEventListener("keydown", onKeyDown);
      window.addEventListener("keyup", onKeyUp);
      window.addEventListener("blur", onBlur);
      function animate(now) {
        const delta = Math.min((now - previousFrame) / 1000, 0.05);
        previousFrame = now;
        if (walkControls?.isLocked) {
          const forward =
            Number(keys.has("KeyW") || keys.has("ArrowUp")) -
            Number(keys.has("KeyS") || keys.has("ArrowDown"));
          const right =
            Number(keys.has("KeyD") || keys.has("ArrowRight")) -
            Number(keys.has("KeyA") || keys.has("ArrowLeft"));
          if (forward || right) {
            const speed = (2 * delta) / Math.hypot(forward, right);
            walkControls.moveForward(forward * speed);
            walkControls.moveRight(right * speed);
            const margin = 0.1;
            camera.position.x = THREE.MathUtils.clamp(
              camera.position.x,
              spawn.bounds.min[0] + margin,
              spawn.bounds.max[0] - margin,
            );
            camera.position.z = THREE.MathUtils.clamp(
              camera.position.z,
              spawn.bounds.min[2] + margin,
              spawn.bounds.max[2] - margin,
            );
            draw();
            if (now - lastPositionUpdate > 250) {
              setPosition(camera.position.toArray());
              lastPositionUpdate = now;
            }
          }
        }
        frame = requestAnimationFrame(animate);
      }
      frame = requestAnimationFrame(animate);
      api.current = {
        walk,
        fit: (id) =>
          fit(
            ISOMETRIC_VIEWS.find((v) => v.id === id)?.direction ||
              ISOMETRIC_VIEWS[0].direction,
          ),
        focus: (id) => {
          let fixture;
          model.traverse((o) => {
            if (o.userData.fixtureID === id) fixture = o;
          });
          if (fixture) fit(ISOMETRIC_VIEWS[0].direction, fixture);
        },
        ghost: (enabled) => {
          originals.forEach((m, o) => {
            o.material = enabled ? faded.get(o) : m;
          });
          draw();
        },
        ceiling: (hidden) => {
          model.traverse((o) => {
            if (o.userData.venuePart === "ceiling") o.visible = !hidden;
          });
          draw();
        },
        async capture(viewID, title) {
          if (disposed) throw new Error("The viewer is closed.");
          const previousCamera = camera,
            size = renderer.getSize(new THREE.Vector2()),
            pixelRatio = renderer.getPixelRatio();
          try {
            renderer.setPixelRatio(1);
            renderer.setSize(1600, 1200, false);
            camera = isometricCamera(
              bounds,
              ISOMETRIC_VIEWS.find((v) => v.id === viewID).direction,
              4 / 3,
            );
            draw();
            const canvas = document.createElement("canvas");
            canvas.width = 1600;
            canvas.height = 1200;
            const ctx = canvas.getContext("2d");
            ctx.drawImage(renderer.domElement, 0, 0);
            ctx.fillStyle = "#101925";
            ctx.fillRect(0, 1152, 1600, 48);
            ctx.fillStyle = "#d8e6f5";
            ctx.font = "20px sans-serif";
            ctx.fillText(
              `${title.slice(0, 70)}  ·  ${viewID.replaceAll("-", " ")}  ·  metres / Y up / front −Z`,
              24,
              1184,
            );
            return await new Promise((resolve, reject) =>
              canvas.toBlob(
                (b) =>
                  b ? resolve(b) : reject(new Error("Image export failed.")),
                "image/png",
              ),
            );
          } finally {
            if (!disposed) {
              camera = previousCamera;
              renderer.setPixelRatio(pixelRatio);
              renderer.setSize(size.x, size.y, false);
              draw();
            }
          }
        },
      };
      onReady(api.current);
      const lost = (e) => {
        e.preventDefault();
        onReady(null);
        onError(
          "The 3D graphics context was lost. Reload this saved snapshot to restore the viewer.",
        );
      };
      renderer.domElement.addEventListener("webglcontextlost", lost);
    } catch (error) {
      onError(`3D viewer unavailable: ${error.message}`);
    }
    return () => {
      disposed = true;
      cancelAnimationFrame(frame);
      if (onClick) renderer?.domElement.removeEventListener("click", onClick);
      if (onKeyDown) window.removeEventListener("keydown", onKeyDown);
      if (onKeyUp) window.removeEventListener("keyup", onKeyUp);
      if (onBlur) window.removeEventListener("blur", onBlur);
      onReady(null);
      api.current = null;
      observer?.disconnect();
      controls?.dispose();
      walkControls?.unlock();
      walkControls?.dispose();
      originals.forEach((m, o) => {
        o.material = m;
      });
      faded.forEach((m) =>
        (Array.isArray(m) ? m : [m]).forEach((v) => v.dispose()),
      );
      model.removeFromParent();
      renderer?.dispose();
      renderer?.domElement.remove();
    };
  }, [model, onReady, onError]);
  useEffect(() => {
    api.current?.ghost(ghost);
  }, [ghost, model]);
  useEffect(() => {
    if (view === "walk") api.current?.walk();
    else if (view !== "focus") api.current?.fit(view);
  }, [view, model]);
  useEffect(() => {
    api.current?.ceiling(hideCeiling);
  }, [hideCeiling, model]);
  return (
    <div className="venue-scene-canvas" ref={host}>
      {position && (
        <output className="venue-walk-position" aria-label="Viewer position">
          X {position[0].toFixed(2)} · Y {position[1].toFixed(2)} · Z{" "}
          {position[2].toFixed(2)} m
        </output>
      )}
    </div>
  );
}
