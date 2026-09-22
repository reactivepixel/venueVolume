import { StagePreview } from "./rig";
import React from "react";
import {
  ArrowUpRight,
  Check,
  ChevronRight,
  Grid2X2,
  Lightbulb,
  MapPin,
  Plus,
  Search,
  SlidersHorizontal,
  X,
} from "lucide-react";

export function Button({
  children,
  primary = false,
  danger = false,
  className = "",
  ...props
}) {
  return (
    <button
      type="button"
      className={`button ${primary ? "primary" : ""} ${danger ? "danger" : ""} ${className}`}
      {...props}
    >
      {children}
    </button>
  );
}
export function Badge({ children, tone = "neutral" }) {
  return <span className={`badge ${tone}`}>{children}</span>;
}
export function Field({ label, children, hint }) {
  return (
    <label className="field">
      <span>{label}</span>
      {children}
      {hint && <small>{hint}</small>}
    </label>
  );
}
export function Panel({ title, subtitle, action, children, className = "" }) {
  return (
    <section className={`panel ${className}`}>
      <div className="panel-heading">
        <div>
          <h2>{title}</h2>
          {subtitle && <p>{subtitle}</p>}
        </div>
        {action}
      </div>
      {children}
    </section>
  );
}
export function Empty({
  title = "Nothing here yet",
  detail = "Create the first item to get this show moving.",
  action,
}) {
  return (
    <div className="empty">
      <div className="empty-icon">
        <Grid2X2 size={28} />
      </div>
      <h2>{title}</h2>
      <p>{detail}</p>
      {action}
    </div>
  );
}
export function Table({ headers, rows }) {
  return (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            {headers.map((h, i) => (
              <th key={i}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, i) => (
            <tr key={i}>
              {row.map((cell, j) => (
                <td key={j}>{cell}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
export function SearchBox({ value, onChange, placeholder = "Search…" }) {
  return (
    <label className="search">
      <Search size={16} />
      <input
        aria-label={placeholder}
        placeholder={placeholder}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
      <span>⌕</span>
    </label>
  );
}
export function Metric({ label, value, detail }) {
  return (
    <div className="metric">
      <span>{label}</span>
      <strong>{value}</strong>
      <small>{detail}</small>
    </div>
  );
}
export function Progress({ label, percent }) {
  return (
    <div className="progress-row">
      <span>{label}</span>
      <div className="progress">
        <div style={{ width: `${percent}%` }} />
      </div>
      <span>{percent}%</span>
    </div>
  );
}
export function RowLink({
  icon: Icon = ChevronRight,
  title,
  detail,
  onClick,
  end,
}) {
  return (
    <button className="row-link" onClick={onClick}>
      <span className="row-icon">
        <Icon size={18} />
      </span>
      <span>
        <strong>{title}</strong>
        <small>{detail}</small>
      </span>
      {end || <ArrowUpRight size={16} />}
    </button>
  );
}

export function Stage(props) {
  return <StagePreview {...props} />;
}

export function Dialog({ title, children, onClose }) {
  const ref = React.useRef(null);
  React.useEffect(() => {
    const el = ref.current;
    el.showModal();
    return () => el.close();
  }, []);
  return (
    <dialog ref={ref} className="dialog" onCancel={onClose}>
      <div className="dialog-heading">
        <h2>{title}</h2>
        <Button aria-label="Close dialog" onClick={onClose}>
          <X size={16} />
        </Button>
      </div>
      {children}
    </dialog>
  );
}
export function FormFooter({ onCancel, label = "Save changes" }) {
  return (
    <div className="form-footer">
      <Button onClick={onCancel}>Cancel</Button>
      <button className="button primary" type="submit">
        <Check size={15} />
        {label}
      </button>
    </div>
  );
}
