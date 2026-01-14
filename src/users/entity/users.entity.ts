import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('doodler_users')
export class Users {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'varchar', length: 256, nullable: true, comment: '密码' })
  password: string;

  @Column({ type: 'varchar', length: 50, nullable: true, comment: '昵称' })
  nickname: string;

  @Column({ type: 'varchar', length: 50, nullable: true, comment: '电子邮箱' })
  email: string;

  @Column({ type: 'varchar', length: 256, nullable: true, comment: '头像' })
  avatar: string;

  @Column({
    type: 'enum',
    enum: ['female', 'male'],
    nullable: true,
    comment: '性别',
  })
  gender: string;

  @Column({
    type: 'varchar',
    length: 20,
    unique: true,
    nullable: true,
    comment: '手机',
  })
  phone: string;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
